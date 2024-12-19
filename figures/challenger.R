source("./figures/defaults.R")

library(magick)

data("Challeng", package = "alr4")
df <- Challeng

df$pct <- df$fail / df$n
fit <- glm(cbind(fail, n) ~ temp, data = df, family = binomial("logit"))
preds <- predict(fit, newdata = data.frame(temp = 53:81), type = "response")
preds <- data.frame(temp = 53:81, prediction = preds * 6)

original <- magick::image_read("./figures/challenger.gif")

p1 <- image_ggplot(original)
p2 <- ggplot(Challeng, aes(temp, fail, col = fail == 0)) +
  geom_point(size = 0.5) +
  geom_line(data = preds, aes(temp, prediction), col = pal_dark_3[2]) +
  scale_y_continuous(breaks = c(0:2)) +
  scale_color_manual(values = c("black", "grey80")) +
  labs(x = "Calculated joint temperature (F°)", y = "Number of incidents") +
  guides(col = "none") +
  theme(plot.margin = unit(c(0, 0, 0, 1), units = "cm"))

p <- p1 + p2

ggsave("./figures/challenger.png", p, dpi = 300,
       width = def_width, height = def_height / 2, units = "in")
