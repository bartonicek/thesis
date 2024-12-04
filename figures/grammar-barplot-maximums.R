source("./figures/defaults.R")

fev <- read.csv("./data/fev.csv")
fev$smoke <- factor(fev$smoke, labels = c("No", "Yes"))

fev2 <- aggregate(fev ~ age + smoke, FUN = max, data = fev)

p <- ggplot(fev2, aes(age, fev, fill = smoke)) +
  geom_bar(stat = "identity", position = "identity", col = "white") +
  scale_fill_manual(values = pal_dark_3) +
  labs(x = "Age", y = "Max FEV", fill = "Smoke") +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"),
        legend.position = c(0.1, 0.875))

ggsave("./figures/grammar-barplot-maximums.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")

