## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE---------------------------------------------------------------
# # install.packages("remotes")
# remotes::install_github("ropensci/slopes")

## ----eval=FALSE---------------------------------------------------------------
# # install.packages("remotes")
# remotes::install_github("ropensci/slopes", dependencies = "Suggests")

## ----eval=FALSE---------------------------------------------------------------
# usethis::edit_r_environ()
# # Then add the following line to the file that opens:
# # MAPBOX_API_KEY=xxxxx # replace XXX with your api key

## -----------------------------------------------------------------------------
library(slopes)
library(sf)

# Load example data
data(lisbon_route)
dem_lisbon <- dem_lisbon()

## -----------------------------------------------------------------------------
sf_linestring_xyz_local <- elevation_add(lisbon_route, dem = dem_lisbon)
head(sf::st_coordinates(sf_linestring_xyz_local))

## ----eval=FALSE---------------------------------------------------------------
# # Requires a MapBox API key and the ceramic package
# # sf_linestring_xyz_mapbox = elevation_add(lisbon_route)
# # head(sf::st_coordinates(sf_linestring_xyz_mapbox))

## -----------------------------------------------------------------------------
slope <- slope_xyz(sf_linestring_xyz_local)
slope

## -----------------------------------------------------------------------------
# For plot_slope() use a symmetric palette: steep slopes are red on both sides
# (downhill and uphill), gentle slopes in the middle are green.
plot_slope(sf_linestring_xyz_local, pal = c(rev(slope_colors), slope_colors))

## -----------------------------------------------------------------------------
lisbon_route_xyz <- elevation_add(lisbon_route, dem = dem_lisbon())
lisbon_route_segments_xyz <- route_to_segments(lisbon_route_xyz)
lisbon_route_segments_xyz$slope <- slope_xyz(lisbon_route_segments_xyz)
summary(lisbon_route_segments_xyz$slope)

## -----------------------------------------------------------------------------
# Segments are coloured by steepness (absolute slope), regardless of direction
# (uphill or downhill). slope_breaks are in proportions, matching slope_xyz() output.
col_idx <- cut(abs(lisbon_route_segments_xyz$slope),
  breaks = slope_breaks, labels = FALSE, include.lowest = TRUE
)
plot(st_geometry(lisbon_route_segments_xyz),
  col = slope_colors[col_idx],
  lwd = 3, main = "Slope by vertex segments"
)

## ----warning=FALSE------------------------------------------------------------
lisbon_route_100m <- stplanr::line_segment(lisbon_route, segment_length = 100)
lisbon_route_100m_xyz <- elevation_add(lisbon_route_100m, dem = dem_lisbon())
lisbon_route_100m_xyz$slope <- slope_xyz(lisbon_route_100m_xyz)
summary(lisbon_route_100m_xyz$slope)

## -----------------------------------------------------------------------------
col_idx <- cut(abs(lisbon_route_100m_xyz$slope),
  breaks = slope_breaks, labels = FALSE, include.lowest = TRUE
)
plot(st_geometry(lisbon_route_100m_xyz),
  col = slope_colors[col_idx],
  lwd = 3, main = "Slope by 100 m segments"
)

