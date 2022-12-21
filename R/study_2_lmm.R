################################################################################

# Study 2 - Reanalysis

################################################################################

library(tidyverse)
library(lme4)
library(lmerTest)

study_2 <- read.csv("./data/Study 2 all data with video numbers.csv") %>% 
  slice(-1, -2) %>% 
  type_convert()

video_ids <- read.csv("./data/Study 2 video and participant number.csv")

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