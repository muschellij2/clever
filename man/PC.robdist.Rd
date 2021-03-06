% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/out_meas.R
\name{PC.robdist}
\alias{PC.robdist}
\title{Computes MCD distances.}
\usage{
PC.robdist(U)
}
\arguments{
\item{U}{An n x Q matrix of PC scores.}
}
\value{
A list with components
\describe{
  \item{robdist}{A vector of length n of with the robust distance estimate
   for each observation.}
 \item{inMCD}{A vector of length n indicating if each observation is within
   the MCD subset.}
 \item{Fparam}{The estimated parameters of the F distribution of MCD
   distances.}
}
}
\description{
Computes robust minimum covariance determinant (MCD) distances across
 the observations (rows).  The MCD method selects a subset of h observations
 whose covariance matrix has minimum determinant across all subsets of size
 h. The MCD distances are Mahalanobis distances using the estimates of
 center (mean) and scale (covariance matrix) based on that subset.
}
