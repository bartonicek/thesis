library(colorspace)
source("./figures/defaults.R")

# This is a truly terrible CSV
df <- read.csv("./data/nz_general_election_2023.csv", skip = 2, nrows = 38)
df <- df[-c(1:3), c(1, 3)]
names(df) <- c("party", "votes")
df$votes <- as.numeric(df$votes)
df <- subset(df, !is.na(votes) & votes > 0)
df <- df[order(-df$votes), ]

df$party <- ifelse(df$votes >= df$votes[3], df$part, "Other")
df <- aggregate(. ~ party, df, sum)
df <- df[order(-df$votes), ]
df$party <- factor(df$party, levels = c(setdiff(df$party, "Other"), "Other"))
levels(df$party) <- c("National", "Labour", "Greens", "Other")
labour_index <- which(df$party == "Labour")

df2 <- df
df2$party <- as.character(df2$party)
df2$party[labour_index] <- "National OR Labour"
df2$votes[labour_index] <- df$votes[labour_index] + df$votes[which(df$party == "National")]

df2 <- df2[order(-df2$votes), ]
df2$party <- factor(df2$party, levels = c(setdiff(df2$party, "Other"), "Other"))

colors2 <- c(palette.colors(6, "paired")[c(1, 3, 2) * 2], "grey80")
colors2[1] <- rgb(t(rowMeans(col2rgb(colors2[1:2]))) / 255)

p <- ggplot(df2, aes(party, votes, fill = party)) +
  geom_bar(stat = "identity", col = "white") +
  scale_y_continuous(labels = scales::comma)  +
  scale_fill_manual(values = colors2) +
  labs(x = "Party", y = "# of votes") +
  guides(fill = "none") +
  clean_theme +
  theme(plot.margin = unit(c(0, 2, 0, 2), units = "cm"))

ggsave("./figures/barplot-notbijection.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")
