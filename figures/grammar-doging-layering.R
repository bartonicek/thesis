source("./figures/defaults.R")

library(patchwork)

fev <- read.csv("./data/fev.csv")
fev$smoke <- factor(fev$smoke, labels = c("No", "Yes"))

p1 <- ggplot(fev, aes(age, fev, fill = smoke)) +
  geom_bar(stat = "summary", fun = "mean",
           position = position_dodge(), col = "white") +
  scale_fill_manual(values = pal_dark_3) +
  labs(x = "Age", y = "Average FEV", fill = "Smoke") +
  theme(legend.position = c(0.15, 0.85))

p2 <- ggplot(fev, aes(age, fev, fill = smoke)) +
  geom_bar(stat = "summary", fun = "mean",
           position = "identity", alpha = 0.5, col = "white") +
  scale_fill_manual(values = pal_dark_3) +
  labs(x = "Age", y = NULL, fill = "Smoke") +
  guides(fill = "none")

p <- p1 + p2

ggsave("./figures/grammar-dodging-layering.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
