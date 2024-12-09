source("./figures/defaults.R")

px <- ggplot(data.frame()) +
  geom_segment(aes(x = -0.8, y = 0, xend = 0.8, yend = 0),
               arrow = arrow(length = unit(0.1, "inches"))) +
  scale_x_continuous(limits = c(-1, 1)) +
  scale_y_continuous(limits = c(-1, 1)) +
  theme_void()

p1 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  labs(x = "Weight", y = "Mileage") +
  guides(col = "none") +
  coord_cartesian(xlim = c(3, 4.25), ylim = c(12.5, 20))

p2 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  labs(x = "Weight", y = "Mileage") +
  guides(col = "none") +
  coord_cartesian(xlim = c(3, 4.25) + 0.75, ylim = c(12.5, 20) - 1.5)

p3 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  labs(x = "Weight", y = "Mileage") +
  guides(col = "none") +
  coord_cartesian(xlim = c(3, 4.25) + 1.5, ylim = c(12.5, 20) - 3)

p <- p1 + px + p2 + px + p3 + plot_layout(widths = c(1, 1/4, 1, 1/4, 1))

ggsave("./figures/panning.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
