source("./figures/defaults.R")

mtcars$fill <- mtcars$wt > 3 & mtcars$wt < 4.25 &
  mtcars$mpg > 12.5 & mtcars$mpg < 20

px <- ggplot(data.frame()) +
  geom_segment(aes(x = -0.8, y = 0.1, xend = 0.8, yend = -0.1),
               arrow = arrow(length = unit(0.05, "inches"), type = "closed")) +
  scale_x_continuous(limits = c(-1, 1)) +
  scale_y_continuous(limits = c(-1, 1)) +
  theme_void()

p0 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  geom_rect(xmin = 3, ymin = 12.5, xmax = 4.25, ymax = 20,
            fill = NA, col = "grey60", lwd = 0.25, lty = "dashed") +
  coord_fixed(ratio = 1/6) +
  guides(col = "none") +
  labs(x = NULL, y = NULL)

p1 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  labs(x = NULL, y = NULL) +
  guides(col = "none") +
  coord_cartesian(xlim = c(3, 4.25), ylim = c(12.5, 20))

p2 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  labs(x = NULL, y = NULL) +
  guides(col = "none") +
  coord_cartesian(xlim = c(3, 4.25) + 0.75, ylim = c(12.5, 20) - 1.5)

p3 <- ggplot(mtcars, aes(wt, mpg, col = fill)) +
  geom_point() +
  scale_color_manual(values = pal_dark_3) +
  labs(x = NULL, y = NULL) +
  guides(col = "none") +
  coord_cartesian(xlim = c(3, 4.25) + 1.5, ylim = c(12.5, 20) - 3)

pb <- p1 + px + p2 + px + p3 + plot_layout(widths = c(1, 1/4, 1, 1/4, 1))
p <- p0 / pb + plot_layout(heights = c(1, 1/2))

ggsave("./figures/panning.png", p, dpi = 300,
       width = def_width, height = 3 / 2 * def_height, units = "in")
