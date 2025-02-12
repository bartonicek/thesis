source("./figures/defaults.R")

df <- read.csv("./data/longterm_care.csv")
# df$fill <- df$diagnosis %in% names(sort(-tapply(df$cases, df$diagnosis, sum)))[1:5]
df$diagnosis2 <- reorder(df$diagnosis, df$cases, \(x) {sum(x)})

px <- ggplot(data.frame()) +
  geom_segment(aes(x = -0.8, y = 0, xend = 0.8, yend = 0),
               arrow = arrow(length = unit(0.05, "inches"), type = "closed")) +
  scale_x_continuous(limits = c(-1, 1)) +
  scale_y_continuous(limits = c(-1, 1)) +
  theme_void()

p1 <- ggplot(df, aes(diagnosis, cases)) +
  geom_bar(stat = "summary", fun = "sum", fill = pal_dark_3[1]) +
  scale_x_discrete(labels = NULL) +
  scale_y_continuous(labels = NULL) +
  labs(x = NULL, y = NULL) +
  guides(fill = "none")

e <- sort(-sort(-tapply(df$cases, df$diagnosis, sum))[5:6])

p2 <- ggplot(df, aes(diagnosis2, cases)) +
  geom_bar(stat = "summary", fun = "sum", fill = pal_dark_3[1]) +
  geom_segment(data = data.frame(), aes(x = 9, y = e[1] + 3.5e3, xend = 9, yend = e[2] - 3.5e3),
               # arrow = arrow(length = unit(0.05, "inches"), end = "both", type = "closed"),
               col = "grey60", lty = "dashed", lwd = 0.25) +
  geom_segment(data = data.frame(), aes(x = 9, y = e[1] + 3e3, xend = 9, yend = e[2] - 3e3),
               arrow = arrow(length = unit(0.05, "inches"), end = "both", type = "closed"),
               col = "grey60", lwd = 0) +
  scale_x_discrete(labels = NULL) +
  scale_y_continuous(labels = NULL) +
  labs(x = NULL, y = NULL) +
  guides(fill = "none")

p <- p1 + px + p2 + plot_layout(widths = c(1, 1/4, 1))

ggsave("./figures/sorting.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")

