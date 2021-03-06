## File Name: diag2.R
## File Version: 0.02

diag2 <- function( vec)
{
    if ( length(vec) > 1){
        res <- diag(vec)
    } else {
        res <- matrix(vec, nrow=1,ncol=1)
    }
    return(res)
}
