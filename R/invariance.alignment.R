## File Name: invariance.alignment.R
## File Version: 3.602


invariance.alignment <- function( lambda, nu, wgt=NULL,
    align.scale=c(1,1), align.pow=c(.25,.25), eps=.01,
    psi0.init=NULL, alpha0.init=NULL, center=FALSE, optimizer="optim", ... )
{
    CALL <- match.call()
    s1 <- Sys.time()
    type <- "AM"

    #-- labels for groups and items
    lambda <- invariance_alignment_proc_labels(x=lambda)
    nu <- invariance_alignment_proc_labels(x=nu)

    #-- weights
    G <- nrow(lambda)   # number of groups
    I <- ncol(lambda)   # number of items
    if ( is.null(wgt) ){
        wgt <- 1+0*nu
    }
    W1 <- dim(wgt)
    wgtM <- matrix( colSums(wgt,na.rm=TRUE), nrow=W1[1], ncol=W1[2], byrow=TRUE )
    wgtM <- wgt / wgtM
    wgt <- G * wgtM

    # missing indicator matrix: 1 - no missings
    missM <- 0.5 * ( (1-is.na(lambda))+ (1- is.na(nu)) )
    wgt <- wgt * missM
    wgt[ missM==0 ] <- 0

    lambda[ missM==0 ] <- mean( lambda, na.rm=TRUE )
    nu[ missM==0 ] <- mean( nu, na.rm=TRUE )
    group.combis <- t( utils::combn(G, 2))
    group.combis <- rbind( group.combis, group.combis[,c(2,1) ] )
    group_combis <- group.combis

    #--- initial estimates means and SDs
    psi0 <- apply(lambda, 1, median)
    psi0 <- psi0 / psi0[1]
    alpha0 <- apply(nu, 1, median, na.rm=TRUE)
    alpha0 <- alpha0 - alpha0[1]
    if ( ! is.null( psi0.init) ){ psi0 <- psi0.init }
    if ( ! is.null( alpha0.init) ){ alpha0 <- alpha0.init }

    lambda <- as.matrix(lambda)
    wgt <- as.matrix(wgt)
    wgt_combi <- matrix(NA, nrow=nrow(group.combis), ncol=ncol(lambda) )
    for (ii in 1:I){
        wgt_combi[,ii] <- sqrt(wgt[ group.combis[,1], ii]*wgt[ group.combis[,2], ii])
    }

    group_combis <- group.combis-1
    G1 <- G-1
    ind_alpha <- seq_len(G1)
    ind_psi <- G1 + ind_alpha

    #-- define optimization functions
    fct_optim <- function(x){
        res <- invariance_alignment_define_parameters(x=x, ind_alpha=ind_alpha, ind_psi=ind_psi)
        val <- sirt_rcpp_invariance_alignment_opt_fct( nu=nu, lambda=lambda, alpha0=res$alpha0,
                    psi0=res$psi0, group_combis=group_combis, wgt=wgt, align_scale=align.scale,
                    align_pow=align.pow, eps=eps, wgt_combi=wgt_combi, type=type )
        val <- val$fopt
        return(val)
    }
    grad_optim <- function(x){
        res <- invariance_alignment_define_parameters(x=x, ind_alpha=ind_alpha, ind_psi=ind_psi)
        grad <- sirt_rcpp_invariance_alignment_opt_grad( nu=nu, lambda=lambda,
                        alpha0=res$alpha0, psi0=res$psi0, group_combis=group_combis, wgt=wgt,
                        align_scale=align.scale, align_pow=align.pow, eps=eps, wgt_combi=wgt_combi,
                        type=type )
        grad <- grad[-c(1,G+1)]
        return(grad)
    }

    #* estimate alignment parameters
    lower <- c(rep(-Inf,G1), rep(.01, G1))
    par <- c( alpha0[-1], psi0[-1] )
    res_optim <- sirt_optimizer(optimizer=optimizer, par=par, fn=fct_optim, grad=grad_optim,
                        lower=lower, hessian=FALSE, ...)
    res <- invariance_alignment_define_parameters(x=res_optim$par, ind_alpha=ind_alpha, ind_psi=ind_psi)
    alpha0 <- res$alpha0
    psi0 <- res$psi0

    # center parameters
    res <- invariance_alignment_center_parameters(alpha0=alpha0, psi0=psi0, center=center)
    alpha0 <- res$alpha0
    psi0 <- res$psi0

    # define aligned parameters
    res <- sirt_rcpp_invariance_alignment_opt_fct( nu=nu, lambda=lambda, alpha0=alpha0,
                    psi0=psi0, group_combis=group_combis, wgt=wgt, align_scale=align.scale,
                    align_pow=align.pow, eps=eps, wgt_combi=wgt_combi, type=type )
    lambda.aligned <- sirt_matrix_names(x=res$lambda, extract_names=lambda)
    nu.aligned <- sirt_matrix_names(x=res$nu, extract_names=nu)
    fopt <- res$fopt

    #*****************************
    # calculate item statistics and R-squared measures
    # groupwise aligned loading
    # average aligned parameter
    itempars.aligned <- data.frame(
                            invariance_alignment_aligned_parameters_summary(x=lambda.aligned, label="lambda"),
                            invariance_alignment_aligned_parameters_summary(x=nu.aligned, label="nu"),
                            row.names=colnames(lambda) )

    M.lambda_matr <- TAM::tam_matrix2( itempars.aligned$M.lambda, nrow=G)
    M.nu_matr <- TAM::tam_matrix2( itempars.aligned$M.nu, nrow=G)
    lambda.resid <- lambda.aligned - M.lambda_matr
    nu.resid <- nu.aligned - M.nu_matr

    # R-squared measures
    Rsquared.invariance <- c(NA,NA)
    names(Rsquared.invariance) <- c("loadings", "intercepts" )
    expl <- psi0 * M.lambda_matr
    Rsquared.invariance["loadings"] <- sirt_rsquared(x=lambda, expl=expl)
    expl <- M.nu_matr +    alpha0 * M.lambda_matr
    Rsquared.invariance["intercepts"] <- sirt_rsquared(x=nu, expl=expl)

    # correlations aligned parameters
    rbar <- c( invariance_alignment_calc_corr(t(lambda.aligned)),
                    invariance_alignment_calc_corr(t(nu.aligned)) )
    es.invariance <- rbind( Rsquared.invariance, sqrt(1-Rsquared.invariance), rbar)
    rownames(es.invariance) <- c("R2", "sqrtU2", "rbar")

    pars <- data.frame(alpha0=alpha0, psi0=psi0)
    rownames(pars) <- rownames(lambda)

    # psi0 <- psi0.min
    # alpha0 <- alpha0.min * psi0.min
    # original in Muthen paper: alpha / psi
    # but in this optimization alpha=alpha / psi
    # and therefore alpha=alpha* x psi
    s2 <- Sys.time()
    time_diff <- s2-s1

    #----- OUTPUT:
    res <- list( pars=pars, itempars.aligned=itempars.aligned,
            es.invariance=es.invariance, center=center, lambda.aligned=lambda.aligned,
            lambda.resid=lambda.resid, nu.aligned=nu.aligned,
            nu.resid=nu.resid, fopt=fopt, align.scale=align.scale, align.pow=align.pow,
            res_optim=res_optim, eps=eps, wgt=wgt, s1=s1, s2=s2, time_diff=time_diff, CALL=CALL)
    class(res) <- "invariance.alignment"
    return(res)
}

