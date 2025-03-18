source("./figures/defaults.R")

p <- ggplot(mtcars, aes(mpg)) +
  geom_histogram(fill = pal_dark_3[1], breaks = c(10, 15, 35))

ggsave("./figures/ggplot-histogram-aes2.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
