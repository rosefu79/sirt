## File Name: rm_summary_trait_distribution.R
## File Version: 0.05

rm_summary_trait_distribution <- function(object)
{
    cat( "Trait Distribution\n" )
    cat( "Mean=", round( object$mu, 3), " SD=", round( object$sigma, 3) )
    cat( "\n\nEAP Reliability=")
    cat(round( object$EAP.rel,3 ) )
    cat( "\n")
}
