################################################################################

# Study 2 - Analysis

################################################################################

library(tidyverse)
library(lme4)
library(lmerTest)
library(cowplot)

study_2 <- read.csv("./data/rehearsal_study-2.csv") %>% 
  slice(-1, -2) %>% 
  type_convert()

video_ids <- read.csv("./data/rehearsal_join-data.csv")

# Wrangling --------------------------------------------------------------------

study_2 <- study_2 %>% 
  rename(
    condition_string = FL_22_DO
  ) %>% 
  extract(
    col = "condition_string",
    into = c("culpability", "confession"),
    regex = "(.*)/(.*)"
  )

study_2 <- study_2 %>% 
  mutate(
    confession_number = case_when(
      confession == "Spontaneous" ~ 0,
      confession == "Coached" ~ 1,
      confession == "Rehearsed1" ~ 2,
      confession == "Rehearsed2" ~ 3
    )
  )

study_2$video <- select(study_2, ends_with("DO"), -Guilt_Innocent_DO) %>% 
  coalesce(!!!.)

study_2 <- study_2 %>% 
  extract(
    col = "video",
    into = "video",
    regex = ".*_.*_(.*)"
  )

study_2$video <- paste(study_2$culpability, study_2$video)

study_2$confession_number_sq <- study_2$confession_number^2

study_2$culpability <- factor(study_2$culpability, levels = c("Innocent", "Guilty")) 

study_2$guilt <- -1*(study_2$Guilt_Innocent - 2)

## Word counts

video_ids <- video_ids %>% 
  left_join(select(study_1_long, ID, confession_number, length), by = c("ID", "confession_number"))

video_ids <- video_ids %>% 
  mutate(
    culpability = case_when(
      Guilt == 0 ~ "Innocent",
      Guilt == 1 ~ "Guilty"
    )
  )

video_ids$video <- paste(video_ids$culpability, video_ids$Video.number)

study_2 <- study_2 %>% 
  left_join(select(video_ids, video, length), by = "video")

# Mixed effects models ---------------------------------------------------------

# Guilt

model_guilt_1 <- glmer(guilt ~ culpability + confession_number + (1|video), data = study_2, family = binomial(link = "logit"))
model_guilt_2 <- glmer(guilt ~ culpability + confession_number + confession_number_sq + (1|video), data = study_2, family = binomial(link = "logit"))
model_guilt_3 <- glmer(guilt ~ culpability * confession_number + culpability * confession_number_sq + (1|video), data = study_2, family = binomial(link = "logit"))

lrt_guilt <- anova(model_guilt_1, model_guilt_2, model_guilt_3)

# Confidence

model_confidence_1 <- lmer(Confidence ~ guilt + culpability + confession_number + (1|video), data = study_2, REML = FALSE)
model_confidence_2 <- lmer(Confidence ~ guilt + culpability + confession_number + confession_number_sq + (1|video), data = study_2, REML = FALSE)
model_confidence_3 <- lmer(Confidence ~ guilt * confession_number + guilt * confession_number_sq + culpability + (1|video), data = study_2, REML = FALSE)

lrt_confidence <- anova(model_confidence_1, model_confidence_2, model_confidence_3)

# Knowledgeable

model_know_1 <- lmer(Knowledgeable ~ culpability + confession_number + (1|video), data = study_2, REML = FALSE)
model_know_2 <- lmer(Knowledgeable ~ culpability + confession_number + confession_number_sq + (1|video), data = study_2, REML = FALSE)
model_know_3 <- lmer(Knowledgeable ~ culpability * confession_number + culpability * confession_number_sq + (1|video), data = study_2, REML = FALSE)

lrt_know <- anova(model_know_1, model_know_2, model_know_3)

# Remorse

model_remorse_1 <- lmer(Remorse ~ culpability + confession_number + (1|video), data = study_2, REML = FALSE)
model_remorse_2 <- lmer(Remorse ~ culpability + confession_number + confession_number_sq + (1|video), data = study_2, REML = FALSE)

lrt_remorse_1_2 <- anova(model_remorse_1, model_remorse_2)

model_remorse_3 <- lmer(Remorse ~ culpability * confession_number + (1|video), data = study_2, REML = FALSE)

lrt_remorse_1_3 <- anova(model_remorse_1, model_remorse_3)

# Detailed

model_detail_1 <- lmer(Detailed ~ culpability + confession_number + (1|video), data = study_2, REML = FALSE)
model_detail_2 <- lmer(Detailed ~ culpability + confession_number + confession_number_sq + (1|video), data = study_2, REML = FALSE)
model_detail_3 <- lmer(Detailed ~ culpability * confession_number + culpability * confession_number_sq + (1|video), data = study_2, REML = FALSE)

lrt_detail <- anova(model_detail_1, model_detail_2, model_detail_3)

# Rehearsed

model_rehearse_1 <- lmer(Rehearsed ~ culpability + confession_number + (1|video), data = study_2, REML = FALSE)
model_rehearse_2 <- lmer(Rehearsed ~ culpability + confession_number + confession_number_sq + (1|video), data = study_2, REML = FALSE)

lrt_rehearse_1_2 <- anova(model_rehearse_1, model_rehearse_2)

model_rehearse_3 <- lmer(Rehearsed ~ culpability * confession_number + (1|video), data = study_2, REML = FALSE)

lrt_rehearse_1_3 <- anova(model_rehearse_1, model_rehearse_3)

# Visualizations ---------------------------------------------------------------

## Guilt proprortions

guilt_table <- study_2 %>% 
  group_by(culpability, confession_number) %>% 
  summarise(
    proportion = sum(guilt)/n(),
    se = sqrt( (proportion * (1 - proportion)) / n() ),
    ci_lb = proportion - se*qnorm(.975),
    ci_ub = proportion + se*qnorm(.975)
  )

guilt_figure <- 
ggplot(guilt_table,
       aes(
         x = confession_number,
         y = proportion,
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
    breaks = seq(0, 1, .10),
    limits = c(0, 1)
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
    y = "Proportion of guilt judgments",
    color = ""
  ) +
  theme_classic()

## Confidence

conf_table <- study_2 %>% 
  group_by(guilt, confession_number) %>% 
  summarise(
    mean = mean(Confidence),
    se    = sd(Confidence, na.rm = TRUE)/sqrt(n()),
    ci_lb = mean - se*qt(.975, n() - 2),
    ci_ub = mean + se*qt(.975, n() - 2)
  )

confidence_figure <- 
ggplot(conf_table,
       aes(
         y = mean,
         x = confession_number,
         color = as.factor(guilt)
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
    breaks = 1:10,
    limits = c(1, 10)
  ) +
  scale_x_continuous(
    labels = paste("Confession", 1:4, sep = " "),
    breaks = 0:3
  ) +
  scale_color_manual(
    values = c("#E71D36", "#448FA3"),
    labels = c("Judged innocent", "Judged guilty")
  ) +
  labs(
    x = "Level of Rehearsal",
    y = "Mean Confidence in Judgment",
    color = ""
  ) +
  theme_classic()

## Perceptual variables

perceptual <- study_2 %>% 
  pivot_longer(
    cols = c("Knowledgeable", "Remorse", "Detailed", "Rehearsed"),
    names_to = "item",
    values_to = "rating"
  )

perceptual_table <- perceptual %>% 
  group_by(culpability, confession_number, item) %>% 
  summarise(
    mean  = mean(rating, na.rm = TRUE),
    se    = sd(rating, na.rm = TRUE)/sqrt(n()),
    ci_lb = mean - se*qt(.975, n() - 2),
    ci_ub = mean + se*qt(.975, n() - 2)
  )

perceptual_figure <- 
  ggplot(perceptual_table,
         aes(
           y = mean,
           x = confession_number,
           color = item
           )) +
  facet_wrap(~ culpability, nrow = 2) +
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
    breaks = 1:10,
    limits = c(1, 10)
  ) +
  scale_x_continuous(
    labels = paste("Confession", 1:4, sep = " "),
    breaks = 0:3
  ) +
  scale_color_manual(
    values = c("#8EA604", "#EC9F05", "#CA3C25", "#2D1E2F")
  ) +
  labs(
    x = "Level of Rehearsal",
    y = "Mean Rating",
    color = ""
  ) +
  theme_classic()

perceptual_figure_alt <-
ggplot(perceptual_table,
       aes(
         y = mean,
         x = confession_number,
         color = culpability
       )) +
  facet_wrap(~ item, nrow = 2) +
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
    breaks = 1:10,
    limits = c(1, 10)
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
    y = "Mean Rating",
    color = ""
  ) +
  theme_classic()

## Export figures

save_plot("./figures/rehearsal_guilt-figure.png", guilt_figure, base_height = 5)
save_plot("./figures/rehearsal_confidence-figure.png", confidence_figure, base_height = 5)
save_plot("./figures/rehearsal_perceptual-figure.png", perceptual_figure_alt, base_height = 6)

# Table of descriptives --------------------------------------------------------

rating_table <- perceptual %>% 
  group_by(item, culpability, confession_number) %>% 
  summarise(
    Mean  = mean(rating, na.rm = TRUE),
    SD    = sd(rating, na.rm = TRUE)
  )

rating_table$confession_number <- rating_table$confession_number + 1

rating_table$Mean <- round(rating_table$Mean, 2)
rating_table$SD <- round(rating_table$SD, 2)

colnames(rating_table) <- c("Rating", "Actual Guilt", "Rehearsal Level", "Mean", "SD")

write.csv(rating_table, "./data/rehearsal_rating-table.csv", row.names = FALSE)
