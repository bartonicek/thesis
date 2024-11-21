library(ggplot2)
library(patchwork)
source("./figures/defaults.R")

p1 <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point(col = pal_dark_3[1]) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  clean_theme +
  theme(plot.margin = unit(c(0, 0.25, 0, 0), units = "cm"))


p2 <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point(col = pal_dark_3[1]) +
  clean_theme +
  theme(plot.margin = unit(c(0, 0, 0, 0.25), units = "cm"))

p <- p1 + p2

ggsave("./figures/expand-scatterplot.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
