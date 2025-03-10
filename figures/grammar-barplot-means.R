source("./figures/defaults.R")

fev <- read.csv("./data/fev.csv")
fev$smoke <- factor(fev$smoke, labels = c("No", "Yes"))

p <- ggplot(fev, aes(age, fev, fill = smoke)) +
  geom_bar(stat = "summary", fun = "mean", col = "white") +
  scale_fill_manual(values = pal_dark_3) +
  labs(x = "Age", y = "Average* FEV", fill = "Smoke") +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"),
        legend.position = c(0.1, 0.875))

ggsave("./figures/grammar-barplot-means.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")

