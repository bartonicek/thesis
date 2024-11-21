
files <- list.files("./figures", "*.R$", full.names = TRUE)
files <- files[!files %in% c("./figures/render-all.R", "./figures/defaults.R")]

for (file in files) {
  system(paste0("Rscript ", file))
}



