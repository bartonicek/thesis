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

p3 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  labs(x = "Weight", y = "Mileage") +
  guides(col = "none") +
  coord_cartesian(xlim = c(3, 4.25), ylim = c(12.5, 20))

p2 <- ggplot(data.frame()) +
  geom_segment(aes(x = -0.8, y = 0, xend = 0.8, yend = 0),
               arrow = arrow(length = unit(0.1, "inches"))) +
  scale_x_continuous(limits = c(-1, 1)) +
  scale_y_continuous(limits = c(-1, 1)) +
  theme_void()

p <- p1 + p2 + p3 + plot_layout(widths = c(1, 1/4, 1))

ggsave("./figures/zooming.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")


