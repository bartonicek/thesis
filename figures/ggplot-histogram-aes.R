source("./figures/defaults.R")

p <- ggplot(mtcars, aes(mpg)) + geom_histogram(fill = pal_dark_3[1])

ggsave("./figures/ggplot-histogram-aes.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
