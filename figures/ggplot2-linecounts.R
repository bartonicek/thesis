source("./figures/defaults.R")

counts <- readLines("./data/ggplot2-linecounts.txt")
counts <- gsub("./", "", trimws(counts))
counts <- data.frame(do.call(rbind, strsplit(trimws(counts), " ")))
names(counts) <- c("lines", "file")
counts$lines <- as.numeric(counts$lines)

counts <- counts[order(-counts$lines), ]
counts <- counts[2:11, ]
counts$file <- factor(counts$file, levels = rev(counts$file))

counts$fill <- counts$file == "scale-.R"

p <- ggplot(counts, aes(y = file, x = lines, fill = fill)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("grey80", pal_dark_3[1])) +
  labs(x = "# of lines", y = "Filename") +
  scale_x_continuous(breaks = 1:8 * 200) +
  guides(fill = "none") +
  scale_y_discrete()

ggsave("./figures/ggplot2-linecounts.png", p, dpi = 300,
       width = def_width, height = def_height, units = "in")

