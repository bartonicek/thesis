source("./figures/defaults.R")

# seed <- sample(1:1e4, 1)
# set.seed(seed)

set.seed(6655)

n <- 50
p <- 0.5
x_ <- 0:n
y_ <- cumsum(rnorm(n + 1, 0, 0.1))

x <- x_[-length(x_)]
y <- y_[-length(y_)]
xend <- x_[-1]
yend <- y_[-1]

group <- sample(rep(c(1, 2), c(floor(p * n), n - floor(p * n))))
sx <- group + rnorm(n, 0, 0.25)
sy <- group + rnorm(n, 0, 0.25)
col <- sx < 1.5 & sy < 1.5

df <- data.frame(x, y, xend, yend, sx, sy, col)

p2 <- ggplot(df, aes(x, y, xend = xend, yend = yend, col = col)) +
  geom_segment(lineend = "round") +
  annotate("text", x = 30, y = 1, label = "?", size = 10) +
  scale_y_continuous(expand = c(0.25, 0.25)) +
  scale_colour_manual(values = pal_dark_3) +
  guides(col = "none") +
  labs(x = NULL, y = NULL)

p1 <- ggplot(df, aes(x = sx, y = sy, col = col)) +
  geom_point() +
  geom_rect(aes(xmin = 0.275, xmax = 1.525, ymin = 0.35, ymax = 1.5),
            fill = NA, col = "grey60", lwd = 0.25, lty = "dashed") +
  scale_colour_manual(values = pal_dark_3) +
  guides(col = "none") +
  labs(x = NULL, y = NULL)

p <- p1 + p2

ggsave("./figures/line-consistency.png", p, dpi = 300,
       width = def_width, height = def_height * 2 / 2, units = "in")

# print(seed)

