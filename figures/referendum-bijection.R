source("./figures/defaults.R")

df_euthanasia <- data.frame(x = c("For", "Against"), y = c(1893290, 979079))
df_cannabis <- data.frame(x = c("For", "Against"), y = c(1406973, 1474635))

df_euthanasia$x <- factor(df_euthanasia$x, levels = c("For", "Against"))
df_cannabis$x <- factor(df_cannabis$x, levels = c("For", "Against"))

p1 <- ggplot(df_euthanasia, aes(x, y, fill = x)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = pal_dark_3) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = NULL, y = "# of votes", fill = "Vote", title = "Euthanasia") +
  guides(fill = "none") +
  clean_theme

p2 <- ggplot(df_cannabis, aes(x, y, fill = x)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = pal_dark_3) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = NULL, y = "# of votes", fill = "Vote", title = "Cannabis") +
  guides(fill = "none") +
  clean_theme

p <- p1 + p2

ggsave("./figures/referendum-bijection.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
