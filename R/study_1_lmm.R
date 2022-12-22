################################################################################

#  Study 1 - Analysis

################################################################################

library(tidyverse)
library(lme4)
library(lmerTest)
library(cowplot)

study_1 <- read.csv("./data/Study 1 data CSV.csv")

# Wrangling

study_1_long <- study_1 %>% 
  pivot_longer(
    cols = starts_with("Conf_"),
    names_to = "confession",
    values_to = "length"
  ) %>% 
  extract(
    col = "confession",
    into = "confession_number",
    regex = "Conf_(.)Length"
  )

study_1_long$confession_number <- as.numeric(study_1_long$confession_number) - 1 

study_1_long$confession_number_sq <- study_1_long$confession_number^2

# Mixed effects models

model_1 <- lmer(length ~ Condition + confession_number + (1|ID), data = study_1_long, REML = FALSE)
model_2 <- lmer(length ~ Condition + confession_number + confession_number_sq + (1|ID), data = study_1_long, REML = FALSE)

lrt_1_2 <- anova(model_1, model_2)

model_3 <- lmer(length ~ Condition * confession_number + Condition * confession_number_sq + (1|ID), data = study_1_long, REML = FALSE)

lrt_2_3 <- anova(model_2, model_3)

# Visualizations ---------------------------------------------------------------

## Guilt proprortions

word_table <- study_1_long %>% 
  group_by(Condition, confession_number) %>% 
  summarise(
    mean = mean(length),
    se    = sd(length, na.rm = TRUE)/sqrt(n()),
    ci_lb = mean - se*qt(.975, n() - 2),
    ci_ub = mean + se*qt(.975, n() - 2)
  )

word_table <- word_table %>% 
  mutate(
    culpability = case_when(
      Condition == 0 ~ "Innocent",
      Condition == 1 ~ "Guilty"
    )
  )

word_table$culpability <- factor(word_table$culpability, levels = c("Innocent", "Guilty"))

word_figure <- 
  ggplot(word_table,
         aes(
           x = confession_number,
           y = mean,
           color = culpability
         )) +
  geom_line(
    linewidth = 1
  ) +
  geom_errorbar(
    aes(
      ymax = ci_ub,
      ymin = ci_lb
    ),
    alpha = .50,
    width = .25
  ) +
  scale_y_continuous(
    breaks = seq(0, 250, 50),
    limits = c(0, 250)
  ) +
  scale_x_continuous(
    labels = paste("Confession", 1:4, sep = " "),
    breaks = 0:3
  ) +
  scale_color_manual(
    values = c("#E71D36", "#448FA3")
  ) +
  labs(
    x = "Level of Rehearsal",
    y = "Word count",
    color = ""
  ) +
  theme_classic()

## Export figures

save_plot("./figures/rehearsal_word-figure.png", word_figure, base_height = 5)
