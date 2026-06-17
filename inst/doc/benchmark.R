## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(slopes)
library(bench)

## ----results='hide'-----------------------------------------------------------
e = dem_lisbon()
r = lisbon_road_network
res = bench::mark(check = FALSE,
  bilinear = slope_raster(r, e),
  simple   = slope_raster(r, e, method = "simple")
)

## -----------------------------------------------------------------------------
res

## -----------------------------------------------------------------------------
round(res$`itr/sec` * nrow(r))

## ----results='hide'-----------------------------------------------------------
res2 = bench::mark(check = FALSE,
  bilinear = slope_raster(r, e, method = "bilinear"),
  simple   = slope_raster(r, e, method = "simple")
)

## -----------------------------------------------------------------------------
res2

## -----------------------------------------------------------------------------
round(res2$`itr/sec` * nrow(r))

