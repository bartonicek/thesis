source("./figures/defaults.R")

mtcars$fill <- mtcars$wt > 3 & mtcars$wt < 4.25 &
  mtcars$mpg > 12.5 & mtcars$mpg < 20

p1 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  geom_rect(xmin = 3, ymin = 12.5, xmax = 4.25, ymax = 20,
            fill = NA, col = "grey60", lwd = 0.25, lty = "dashed") +
  guides(col = "none") +
  labs(x = "Weight", y = "Mileage")

p2 <- ggplot(mtcars, aes(cyl, fill = fill)) +
  geom_bar() +
  scale_fill_manual(values = pal_dark_3) +
  guides(fill = "none") +
  labs(x = "Cylinders", y = "Count")

p3 <- ggplot(mtcars, aes(disp, fill = fill)) +
  geom_histogram(boundary = 0, binwidth = 50) +
  scale_fill_manual(values = pal_dark_3) +
  guides(fill = "none") +
  labs(x = "Displacement", y = "Count")

p4 <- ggplot(mtcars, aes(factor(am, labels = c("Manual", "Automatic")),
                   disp, fill = fill)) +
  geom_boxplot(size = 0.25) +
  scale_fill_manual(values = pal_dark_3) +
  guides(fill = "none") +
  labs(x = NULL, y = "Count")

p <- (p1 + p2) / (p3 + p4)

ggsave("./figures/linked-selection.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
