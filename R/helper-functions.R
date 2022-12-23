################################################################################

#  Helper Functions

################################################################################

ci_lmer <- function(model, digits = 2) {
  
  lmer_coef <- as.data.frame(summary(model)$coefficients)
  
  b     <- lmer_coef$Estimate
  ci_ub <- b + lmer_coef$`Std. Error`  * qt(.975, lmer_coef$df)
  ci_lb <- b - lmer_coef$`Std. Error`  * qt(.975, lmer_coef$df)
  
  b_round     <- round(b, digits)
  ci_ub_round <- round(ci_ub, digits)
  ci_lb_round <- round(ci_lb, digits)
  
  out <- paste(b_round, ", 95% CI [", ci_lb_round, ", ", ci_ub_round, "]", sep = "")
  
  names(out) <- row.names(lmer_coef)
  
  return(out)
  
}

ci_glmer <- function(model, digits = 2) {
  
  glmer_coef <- as.data.frame(summary(model)$coefficients)
  
  b     <- glmer_coef$Estimate
  ci_ub <- b + glmer_coef$`Std. Error`  * qnorm(.975)
  ci_lb <- b - glmer_coef$`Std. Error`  * qnorm(.975)
  
  b_round     <- round(b, digits)
  ci_ub_round <- round(ci_ub, digits)
  ci_lb_round <- round(ci_lb, digits)
  
  out <- paste(b_round, ", 95% CI [", ci_lb_round, ", ", ci_ub_round, "]", sep = "")
  
  names(out) <- row.names(glmer_coef)
  
  return(out)
  
}
