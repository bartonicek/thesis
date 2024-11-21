library(ggplot2)
library(patchwork)

def_width <- 5
def_height <- 3

pal_paired_1 <- palette.colors(2, "Paired")
pal_paired_3 <- palette.colors(6, "Paired")[c(1, 2, 5, 6, 3, 4)]
pal_light_3 <- pal_paired_3[1:3]
pal_dark_3 <- pal_paired_3[2 * 1:3]

clean_theme <-
  theme_bw(base_size = 6) +
  theme(axis.ticks = element_blank(),
        panel.grid = element_blank(),
  )

tex_to_png <- function(filename) {
  tinytex::pdflatex(paste0("./figures/", filename,".tex"))
  img <- magick::image_read_pdf(paste0("./figures/", filename,".pdf"), density = 300)
  magick::image_write(img, path = paste0("./figures/", filename,".png"), density = 300)
}



