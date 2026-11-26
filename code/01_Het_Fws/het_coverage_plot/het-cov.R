
library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyr)
library(scales)


# ============================================================
# 1. Load data
# ============================================================
df <- read.table(file = "/data/01_Het_Fws/het-cov.txt", header = T, row.names = NULL)
df$ID <- factor(df$ID, levels = df$ID)

# Long format for the three coverage levels
df_long <- df %>%
  select(ID, Coverage_1x, Coverage_10x, Coverage_30x) %>%
  pivot_longer(
    cols = c(Coverage_1x, Coverage_10x, Coverage_30x),
    names_to = "Coverage_Level",
    values_to = "Coverage_Value"
  ) %>%
  mutate(
    Coverage_Level = factor(Coverage_Level,
                            levels = c("Coverage_1x", "Coverage_10x", "Coverage_30x"),
                            labels = c("1x", "10x", "30x"))
  )

# ============================================================
# 2. Palette: shapes + light -> dark colors for coverage depth
# ============================================================

category_colors <- c("Single_oocyst" = "#FFD456", "Single_sporozoite" = "#7F88CB")

# 1x lightest -> 30x darkest (sequential red)
coverage_colors <- c("1x" = "#FCBBA1", "10x" = "#EF6548", "30x" = "#99000D")
coverage_shapes <- c("1x" = 16, "10x" = 17, "30x" = 18)   # circle, triangle, diamond

# Shared theme
base_theme <- theme_minimal(base_size = 12) +
  theme(
    axis.text.x  = element_text(angle = 45, hjust = 1, size = 10, color = "black"),
    axis.text.y  = element_text(color = "black", size = 11),
    axis.title   = element_text(face = "bold", size = 12),
    panel.grid.major = element_line(color = "grey88", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5),
    plot.margin  = margin(4, 4, 4, 4),
    legend.position = "top",
    legend.title = element_text(face = "bold", size = 11),
    legend.text  = element_text(size = 10),
    legend.box   = "horizontal"
  )

# ============================================================
# 3. Left panel: heterozygosity bars
# ============================================================

p_het <- ggplot(df, aes(x = ID, y = Heterozygosity, fill = Category)) +
  geom_col(width = 0.7, alpha = 0.9) +
  scale_fill_manual(values = category_colors, name = "Category") +
  scale_y_continuous(
    name = "Heterozygosity",
    limits = c(0, 1.1),
    breaks = seq(0, 1, by = 0.2),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(x = "Sample ID") +
  base_theme

# ============================================================
# 4. Right panel: coverage scatter (shape + light-to-dark color)
# ============================================================

p_cov <- ggplot(df_long,
                aes(x = ID, y = Coverage_Value,
                    color = Coverage_Level, shape = Coverage_Level,
                    group = Coverage_Level)) +
  geom_point(size = 2.9, stroke = 0.9,
             position = position_dodge(width = 0.6)) +
  scale_color_manual(values = coverage_colors, name = "Coverage depth") +
  scale_shape_manual(values = coverage_shapes, name = "Coverage depth") +
  scale_y_continuous(
    name = "Breadth of coverage (%)",
    limits = c(0, 100),
    breaks = seq(0, 100, by = 20),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(x = "Sample ID") +
  base_theme +
  theme(
    axis.title.y = element_text(color = "black", face = "bold", size = 12),
    axis.text.y  = element_text(color = "black", size = 11)
  )

# ============================================================
# 5. Combine side by side, save
# ============================================================

p <- p_het + p_cov +
  plot_layout(widths = c(1, 1), guides = "collect") +
  plot_annotation(tag_levels = "A") &
  theme(
    legend.position = "top",
    plot.tag = element_text(face = "bold", size = 14)
  )

print(p)

ggsave("/results/01_Het_Fws/het_coverage_plot/heterozygosity_coverage_split.png", plot = p,
       width = 12, height = 4, dpi = 300)
ggsave("/results/01_Het_Fws/het_coverage_plot/heterozygosity_coverage_split.pdf", plot = p,
       width = 12, height = 4)

