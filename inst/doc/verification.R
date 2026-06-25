## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(slopes)
library(sf)

## ----eval=FALSE---------------------------------------------------------------
# u = "https://downloads.rijkswaterstaatdata.nl/nwb-wegen/geogegevens/shapefile/NWB_hoogtebestand/01-10-2024%20Hoogtes_Rijkswegen.zip"
# f_zip = "NWB_hoogtebestand.zip"
# if (!file.exists(f_zip)) {
#   download.file(u, f_zip)
#   unzip(f_zip)
#   # Datasets in
#   list.files("NWB3D_resultaten_oktober_2024.gdb")
#   roads_nl_layers = sf::st_layers("NWB3D_resultaten_oktober_2024.gdb")
# #   Driver: OpenFileGDB
# # Available layers:
# #                                   layer_name        geometry_type features
# # 1    NWB3D_resultaten_oktober_2024_wegvakken 3D Multi Line String    16456
# # 2 NWB3D_resultaten_oktober_2024_vertexpunten             3D Point  1095615
# #   fields            crs_name
# # 1     59 Amersfoort / RD New
# # 2     59 Amersfoort / RD New
#   roads_nl = sf::st_read("NWB3D_resultaten_oktober_2024.gdb", layer = "NWB3D_resultaten_oktober_2024_wegvakken")
#   names(roads_nl)
# #    [1] "WVK_ID"        "BST_CODE"      "WVK_BEGDAT"    "JTE_ID_BEG"
# #  [5] "JTE_ID_END"    "WEGBEHSRT"     "WEGNUMMER"     "WEGDEELLTR"
# #  [9] "HECTO_LTTR"    "RPE_CODE"      "ADMRICHTNG"    "RIJRICHTNG"
# # [13] "STT_NAAM"      "STT_BRON"      "WPSNAAM"       "GME_ID"
# # [17] "GME_NAAM"      "HNRSTRLNKS"    "HNRSTRRHTS"    "E_HNR_LNKS"
# # [21] "E_HNR_RHTS"    "L_HNR_LNKS"    "L_HNR_RHTS"    "BEGAFSTAND"
# # [25] "ENDAFSTAND"    "BEGINKM"       "EINDKM"        "POS_TV_WOL"
# # [29] "WEGBEHCODE"    "WEGBEHNAAM"    "DISTRCODE"     "DISTRNAAM"
# # [33] "DIENSTCODE"    "DIENSTNAAM"    "WEGTYPE"       "WGTYPE_OMS"
# # [37] "ROUTELTR"      "ROUTENR"       "ROUTELTR2"     "ROUTENR2"
# # [41] "ROUTELTR3"     "ROUTENR3"      "ROUTELTR4"     "ROUTENR4"
# # [45] "WEGNR_AW"      "WEGNR_HMP"     "GEOBRON_ID"    "GEOBRON_NM"
# # [49] "BRONJAAR"      "OPENLR"        "BAG_ORL"       "FRC"
# # [53] "FOW"           "ALT_NAAM"      "ALT_NR"        "REL_HOOGTE"
# # [57] "Hoogte_bron"   "Kwaliteitlaag" "SHAPE_Length"  "SHAPE"
# # Plot the slopes (variable called REL_HOOGTE):
#   summary(roads_nl$REL_HOOGTE)
#   # xyz
#   roads_nl_xyz = sf::st_coordinates(roads_nl)
#   head(roads_nl_xyz)
#   hist(roads_nl_xyz[, "Z"], breaks = 50, main = "Histogram of elevation values (m)", xlab = "Elevation (m)")
#   plot(roads_nl["REL_HOOGTE"])
#   summary(sf::st_geometry_type(roads_nl))
#   roads_nl$slope = roads_nl |>
#     sf::st_cast("LINESTRING") |>
#     slopes::slope_xyz() * 100
# 
#   summary(roads_nl$slope)
#   library(tmap)
#   library(tmap.mapgl)
#   m = tm_shape(roads_nl) +
#     tm_lines(
#       col = "slope",
#       col.scale = tm_scale_intervals(
#         breaks = c(-1, 0.5, 1, 2, 20),
#         labels = c("0-0.5%", "0.5-1%", "1-2%", "2%+"),
#         values = cols4all::c4a("-brewer.rd_yl_gn")
#       ),
#       lwd = 5
#   )
#   tmap_mode("maplibre")
#   m
# }

## ----eval=FALSE---------------------------------------------------------------
# # Load the NL data (see code above) and focus on South Limburg
# roads_wgs84 = sf::st_transform(roads_nl, 4326)
# coords_centroid = sf::st_coordinates(sf::st_centroid(st_geometry(roads_wgs84)))
# in_limburg = coords_centroid[, "Y"] > 50.75 &
#              coords_centroid[, "Y"] < 51.0 &
#              coords_centroid[, "X"] > 5.6 &
#              coords_centroid[, "X"] < 6.1
# roads_limburg = roads_nl[in_limburg, ]
# 
# # Pick 30 segments with most Z variation
# get_z_range = function(geom) {
#   c = sf::st_coordinates(geom)
#   if (nrow(c) < 2) return(0)
#   diff(range(c[, "Z"]))
# }
# z_ranges = sapply(sf::st_geometry(roads_limburg), get_z_range)
# top_idx = order(z_ranges, decreasing = TRUE)[1:30]
# roads_sample = roads_limburg[top_idx, ]
# 
# # Download DEM via elevatr (AWS Open Data, no API key required)
# library(elevatr)
# roads_sample_wgs84 = sf::st_transform(roads_sample, 4326)
# bb = sf::st_bbox(roads_sample_wgs84)
# # Buffer the bbox by ~1 km to ensure all vertices are covered
# bb_mat = matrix(c(
#   bb["xmin"] - 0.01, bb["ymin"] - 0.01,
#   bb["xmax"] + 0.01, bb["ymin"] - 0.01,
#   bb["xmax"] + 0.01, bb["ymax"] + 0.01,
#   bb["xmin"] - 0.01, bb["ymax"] + 0.01,
#   bb["xmin"] - 0.01, bb["ymin"] - 0.01
# ), ncol = 2, byrow = TRUE)
# bb_sf = sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(bb_mat)), crs = 4326))
# dem_elevatr = get_elev_raster(bb_sf, z = 10, clip = "bbox")
# # Project DEM to match the NL data CRS (EPSG:28992)
# dem_28992 = terra::project(terra::rast(dem_elevatr), "EPSG:28992", method = "bilinear")
# 
# # Prepare roads: cast to LINESTRING and record actual Z values
# roads_ls = sf::st_cast(roads_sample, "LINESTRING")
# coords_before = sf::st_coordinates(roads_ls)
# actual_z = coords_before[, "Z"]
# 
# # Add elevation from the DEM using the slopes package
# roads_with_z = slopes::elevation_add(roads_ls, dem = dem_28992)
# coords_after = sf::st_coordinates(roads_with_z)
# est_z = coords_after[, "Z"]
# 
# # Compare Z values
# z_diff = est_z - actual_z
# cat("Z RMSE:", round(sqrt(mean(z_diff^2)), 2), "m\n")
# cat("Z MAE:", round(mean(abs(z_diff)), 2), "m\n")
# cat("Z correlation (r):", round(cor(est_z, actual_z), 3), "\n")
# cat("Z mean bias:", round(mean(z_diff), 2), "m\n")
# 
# # Compare slopes (both in EPSG:28992, so lonlat = FALSE)
# slopes_actual = slopes::slope_xyz(roads_ls, lonlat = FALSE) * 100
# slopes_est = slopes::slope_xyz(roads_with_z, lonlat = FALSE) * 100
# cat("Slope correlation (r):",
#     round(cor(slopes_actual, slopes_est, use = "complete.obs"), 3), "\n")
# cat("Slope RMSE:",
#     round(sqrt(mean((slopes_est - slopes_actual)^2, na.rm = TRUE)), 3), "%\n")

## ----eval=FALSE---------------------------------------------------------------
# download.file("https://ndownloader.figshare.com/files/14331185", "3DGRT_AXIS_EPSG25830_v2.zip")
# unzip("3DGRT_AXIS_EPSG25830_v2.zip")
# trace = sf::read_sf("3DGRT_AXIS_EPSG25830_v2.shp")
# plot(trace)
# nrow(trace)
# #> 11304
# summary(trace$X3DGRT_h)
# #>  Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
# #>   642.9   690.3   751.4   759.9   834.3   884.9

## ----eval=FALSE, echo=FALSE---------------------------------------------------
# # original trace dataset
# traces = sf::read_sf("vignettes/3DGRT_TRACES_EPSG25830_v2.shp")
# traces = sf::read_sf("3DGRT_TRACES_EPSG25830_v2.shp")
# nrow(traces)
# #> [1] 111113

## -----------------------------------------------------------------------------
res_gps = c(0.00, 4.58, 1136.36, 6.97)
res_final = c(0.00, 4.96, 40.70, 3.41)
res = data.frame(cbind(
  c("GPS", "Dual frequency GNSS receiver"),
  rbind(res_gps, res_final)
))
names(res) = c("Source", "min", " mean", " max", " stdev")
knitr::kable(res, row.names = FALSE)

## ----eval=FALSE---------------------------------------------------------------
# # mapview::mapview(trace) # check extent: it's above 6km in height
# # remotes::install_github("hypertidy/ceramic")
# loc = colMeans(sf::st_coordinates(sf::st_transform(trace, 4326)))
# e = ceramic::cc_elevation(loc = loc[1:2], buffer = 3000)
# trace_projected = sf::st_transform(trace, 3857)
# plot(e)
# plot(trace_projected$geometry, add = TRUE)

## ----echo=FALSE, eval=FALSE---------------------------------------------------
# # aim: get max distance from centrepoint
# bb = sf::st_bbox(sf::st_transform(trace, 4326))
# geosphere::distHaversine(c(bb[1], bb[2]), c(bb[3], bb[2]))
# geosphere::distHaversine(c(bb[1], bb[2]), c(bb[1], bb[4]))
# # max of those 2 and divide by 2

## ----echo=FALSE---------------------------------------------------------------
knitr::include_graphics("https://user-images.githubusercontent.com/1825120/81125221-75c06780-8f2f-11ea-8cea-ad6322ef99e7.png")

## ----eval=FALSE---------------------------------------------------------------
# # source: https://www.robinlovelace.net/presentations/munster.html#31
# points2line_trajectory = function(p) {
#   c = st_coordinates(p)
#   i = seq(nrow(p) - 2)
#   l = purrr::map(i, ~ sf::st_linestring(c[.x:(.x + 1), ]))
#   lfc = sf::st_sfc(l)
#   a = seq(length(lfc)) + 1 # sequence to subset
#   p_data = cbind(sf::st_set_geometry(p[a, ], NULL))
#   sf::st_sf(p_data, geometry = lfc)
# }
# r = points2line_trajectory(trace_projected)
# # summary(st_length(r)) # mean distance is 1m! Doesn't make sense, need to create segments
# s = slope_raster(r, e = e)
# slope_summary = data.frame(min = min(s), mean = mean(s), max = max(s), stdev = sd(s))
# slope_summary = slope_summary * 100
# knitr::kable(slope_summary, digits = 1)

## ----eval=FALSE, echo=FALSE---------------------------------------------------
# # failed tests
# raster::extract(e, trace_projected)
# raster::writeRaster(e, "e.tif")
# e_terra = terra::rast("e.tif")
# terra::crs(e_terra)
# v = terra::vect("vignettes/3DGRT_TRACES_EPSG25830_v2.shp")
# e_wgs = terra::project(e_terra, v)
# e_stars = stars::st_as_stars(e)
# e_wgs = sf::st_transform(e_stars, 4326)
# stars::write_stars(e_wgs, "e_wgs.tif")
# e2 = raster::raster("e_wgs.tif")
# raster::plot(e)
# plot(trace$geometry, add = TRUE)

## ----echo=FALSE, eval=FALSE---------------------------------------------------
# # discarded way:
# remotes::install_github("jhollist/elevatr")
# sp_bbox = sp::bbox(sf::as_Spatial(sf::st_transform(trace, 4326)))
# e = elevatr::get_aws_terrain(locations = sp_bbox, prj = "+init:4326")

