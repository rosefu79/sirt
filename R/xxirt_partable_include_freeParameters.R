## File Name: xxirt_partable_include_freeParameters.R
## File Version: 0.08



xxirt_partable_include_freeParameters <- function( partable, x ){
        vals <- x[ partable$parindex ]
        ind <- is.na(vals)
        vals[ ind ] <- partable$value[ ind ]
        partable$value <- vals
        return(partable)
}

