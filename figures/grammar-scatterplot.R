source("./figures/defaults.R")

fev <- read.csv("./data/fev.csv")
fev$smoke <- factor(fev$smoke, labels = c("No", "Yes"))

p <- ggplot(fev, aes(age, fev, col = smoke)) +
  geom_point(size = 0.5) +
  scale_colour_manual(values = pal_dark_3) +
  labs(x = "Age", y = "FEV", col = "Smoker") +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"),
        legend.position = c(0.1, 0.875))

ggsave("./figures/grammar-scatterplot.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
