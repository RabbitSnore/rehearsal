################################################################################

#  Study 1 - Analysis

################################################################################

library(tidyverse)
library(lme4)
library(lmerTest)

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