library(magick)

p1 <- image_read("./figures/mondrian1.png")
p2 <- image_read("./figures/mondrian2.png")

p1 <- p1 |> image_resize("700x400!") |> image_border("#ffffff", "10x10")
p2 <- p2 |> image_border("#ffffff", "10x10")

p3 <- image_append(c(p1, p2))
p3 <- image_resize(p3, "2000x2000")

image_write(p3, "./figures/mondrian.png")

