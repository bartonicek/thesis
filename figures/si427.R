library(magick)

p1 <- image_read("./figures/Si427a.jpg")
p2 <- image_read("./figures/Si427b.jpg")

p1 <- image_border(p1, "#ffffff", "10x10")
p2 <- image_border(p2, "#ffffff", "10x10")

p3 <- image_append(c(p1, p2))

image_write(p3, "./figures/si427.jpg")
