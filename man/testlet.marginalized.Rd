%% File Name: testlet.marginalized.Rd
%% File Version: 0.22

\name{testlet.marginalized}
\alias{testlet.marginalized}
%- Also NEED an '\alias' for EACH other topic documented here.

\title{
Marginal Item Parameters from a Testlet (Bifactor) Model
}
\description{
This function computes marginal item parameters of a general
factor if item parameters from a testlet (bifactor) model are
provided as an input (see Details).
}


\usage{
testlet.marginalized(tam.fa.obj=NULL,a1=NULL, d1=NULL, testlet=NULL,
      a.testlet=NULL, var.testlet=NULL)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
\item{tam.fa.obj}{Optional object of class \code{tam.fa}
    generated by \code{\link[TAM:tam.fa]{TAM::tam.fa}} from
    the \pkg{TAM} package. }
  \item{a1}{
Vector of item discriminations of general factor
}
  \item{d1}{
Vector of item intercepts of general factor
}
  \item{testlet}{
Integer vector of testlet (bifactor) identifiers (must be integers
between 1 to \eqn{T}).
}
  \item{a.testlet}{
Vector of testlet (bifactor) item discriminations
}
  \item{var.testlet}{
Vector of testlet (bifactor) variances
}
}

\details{
A testlet (bifactor) model is assumed to be estimated:
\deqn{P(X_{pit}=1 | \theta_{p}, u_{pt} )=
invlogit( a_{i1} \theta_p + a_t u_{pt} - d_{i} ) }
with \eqn{Var( u_{pt} )=\sigma_t^2 }. This multidimensional
item response model with locally independent items is
equivalent to a unidimensional IRT model with locally
dependent items (Ip, 2010). Marginal item parameters \eqn{a_i^\ast}
and \eqn{d_i^\ast} are obtained according to the response
equation \deqn{P(X_{pit}=1 | \theta_{p}^\ast  )=
invlogit( a_{i}^\ast \theta_p^\ast - d_{i}^\ast ) }
Calculation details can be found in Ip (2010).
}

\value{
A data frame containing all input item parameters and
marginal item intercept \eqn{d_i^\ast} (\code{d1_marg}) and
marginal item slope \eqn{a_i^\ast} (\code{a1_marg}).
}

\references{
Ip, E. H. (2010). Empirically indistinguishable multidimensional
IRT and locally dependent unidimensional item response models.
\emph{British Journal of Mathematical and Statistical Psychology,
63}, 395-416.
}


%\author{
%Alexander Robitzsch
%}



%%\note{
%%  ~~further notes~~
%% }

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
For estimating a testlet (bifactor) model see
\code{\link[TAM:tam.fa]{TAM::tam.fa}}.
}

\examples{
#############################################################################
# EXAMPLE 1: Small numeric example for Rasch testlet model
#############################################################################

# Rasch testlet model with 9 items contained into 3 testlets
# the third testlet has essentially no dependence and therefore
# no testlet variance
testlet <- rep( 1:3, each=3 )
a1 <- rep(1, 9 )   # item slopes first dimension
d1 <- rep( c(-1.25,0,1.5), 3 ) # item intercepts
a.testlet <- rep( 1, 9 )  # item slopes testlets
var.testlet <- c( .8, .2, 0 )  # testlet variances

# apply function
res <- sirt::testlet.marginalized( a1=a1, d1=d1, testlet=testlet,
            a.testlet=a.testlet, var.testlet=var.testlet )
round( res, 2 )
  ##    item testlet a1    d1 a.testlet var.testlet a1_marg d1_marg
  ##  1    1       1  1 -1.25         1         0.8    0.89   -1.11
  ##  2    2       1  1  0.00         1         0.8    0.89    0.00
  ##  3    3       1  1  1.50         1         0.8    0.89    1.33
  ##  4    4       2  1 -1.25         1         0.2    0.97   -1.21
  ##  5    5       2  1  0.00         1         0.2    0.97    0.00
  ##  6    6       2  1  1.50         1         0.2    0.97    1.45
  ##  7    7       3  1 -1.25         1         0.0    1.00   -1.25
  ##  8    8       3  1  0.00         1         0.0    1.00    0.00
  ##  9    9       3  1  1.50         1         0.0    1.00    1.50

\dontrun{
#############################################################################
# EXAMPLE 2: Dataset reading
#############################################################################

library(TAM)
data(data.read)
resp <- data.read
maxiter <-  100

# Model 1: Rasch testlet model with 3 testlets
dims <- substring( colnames(resp),1,1 )  # define dimensions
mod1 <- TAM::tam.fa( resp=resp, irtmodel="bifactor1", dims=dims,
               control=list(maxiter=maxiter) )
# marginal item parameters
res1 <- sirt::testlet.marginalized( mod1 )

#***
# Model 2: estimate bifactor model but assume that items 3 and 5 do not load on
#           specific factors
dims1 <- dims
dims1[c(3,5)] <- NA
mod2 <- TAM::tam.fa( resp=resp, irtmodel="bifactor2", dims=dims1,
              control=list(maxiter=maxiter) )
res2 <- sirt::testlet.marginalized( mod2 )
res2
}
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{Testlet model}
\keyword{Bifactor model}% __ONLY ONE__ keyword per line
