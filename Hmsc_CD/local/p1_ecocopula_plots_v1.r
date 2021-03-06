getwd()

library(Hmsc)
wd <- here::here()
wd
setwd(wd)


## Ecocopula plots ######

library(ggplot2)
library(cowplot)
library(mvabund)

## load ecocopula results
# load("Hmsc_CD/local/ecocopula_modList_pilot.rdata") # fm, cor.preds, modList
# load("Hmsc_CD/local/ecocopula_modList_topo.rdata") # fm, cor.preds, modList
load("Hmsc_CD/oregon_ada/results/ecocopula/ecocopula_modlist_pilot.rdata") # load fm below
load("Hmsc_CD/oregon_ada/results/ecocopula/ecocopula_modlist_v3.rdata") # 

str(modList, max.level =2)
# print formulae
fm

## ANOVA summary
an <- modList[[6]]$summ
an$coefficients

sumT <- print.summary.manyglm(an)

lapply(modList, function(x) x$summ)

##### Plots
source("Hmsc_CD/local/fn_ecoCopula_plot.r")## modified plot functions...
cor.preds <- colnames(site_res)[sapply(site_res, is.numeric)]
cor.preds <- cor.preds[!cor.preds %in% c("Factor1","Factor2")]



mod <- modList[[6]]$mod
sp_res <- modList[[6]]$sp
site_res <- modList[[6]]$site
mod.ord <- modList[[6]]$ord

head(site_res)


alpha <- 4*0.95

# chk residuals
plot(mod) 

ggplot() + 
  geom_segment(aes(x = 0, y = 0, 
                   xend = Factor1 * alpha * 0.95, 
                   yend = Factor2 * alpha * 0.95), 
               data = sp_res, 
               size = .1) +
  geom_point(aes(x = Factor1, y = Factor2,
                 color = be10,
                 size = ht,
                 shape = insideHJA), 
                 data = site_res)+
  scale_color_gradientn(colours = brewer.pal(n = 10, name = "RdYlBu"))

#plot factors
plot_factors(alpha, "pa", "mod1", sp_res, site_res, cont_pred1 = "be10", cont_pred2 = "ht")


# Plot over coords with factors as colour fill
plot_xy_factor1("pa", "mod1", site_res, cont_pred2 = ht)
plot_xy_factor2("pa", "mod1", site_res, cont_pred2 = ht)

## correlation plot
cor.preds <- colnames(site_res)[sapply(site_res, is.numeric)]
cor.preds <- cor.preds[!cor.preds %in% c("Factor1","Factor2")]
mod.cor <- cor(mod.ord$scores, site_res[,cor.preds])
t_corrplot(mod.cor, "mod1")


## loop over list and do all plots

# i = 1
alpha <- 4*0.95

for(i in seq_along(modList)){
  

  mod <- modList[[i]]$mod
  mod.ord <- modList[[i]]$ord
  sp_res <- modList[[i]]$sp
  site_res <- modList[[i]]$site
  an <- modList[[i]]$summ # if missing, will be NULL
  
  
  #  # get predictors and significance if done anova, not then just predictors
  if(!is.null(an)){
    
    preds <- rownames(an$coefficients)
    stars <- symnum(an$coefficients[, 2], 
                     corr = FALSE, na = FALSE, 
                     cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1), 
                     symbols = c("***", "**", "*", ".", " "))
    stars <- stars[!preds == "(Intercept)"]
    preds <- preds[!preds == "(Intercept)"]
    
    modName <- paste("predictors:", paste0(preds, stars, collapse = " + "))
    
    
  } else  modName <- paste0("predictors: ", as.character(fm[[i]])[3])

  # chk residuals
  # plot(mod) 
  
  #plot factors
  p1 <- plot_factors(alpha, "pa", "", sp_res, site_res, cont_pred1 = "be10", cont_pred2 = "ht")
  
  
  ## correlation plot
  mod.cor <- cor(mod.ord$scores, site_res[,cor.preds])
  p2 <- ~t_corrplot(mod.cor, "")
  
  # Plot over coords with factors as colour fill
  p3 <- plot_xy_factor1("pa", "", site_res, cont_pred2 = ht)
  p4 <- plot_xy_factor2("pa", "", site_res, cont_pred2 = ht)
  
  # put rows together
  pA <- plot_grid(p2, p1, rel_widths = c(4,5), align = "h", axis = "t")
  pB <- plot_grid(p3, p4) # p4
  
  title <- ggdraw() + 
    draw_label(modName, fontface = 'bold', size = 15, x = 0.0, y = 0.5, hjust = 0)
    
  m1 <- plot_grid(pA, pB, title, nrow = 3, rel_heights = c(4,5,1))
  # m1 <- plot_grid(pA, pB, nrow = 2, rel_heights = c(4,5))
  # m1
  ggsave(paste0("Hmsc_CD/local/plots/mod_topo3_", i, ".png"), m1, width = 300, height = 250, units = "mm")
}


## Summary of ANOVA









## plot factors on map

# get coordiantes
source("Hmsc_CD/local/L1_read_data.r")
# otu.pa.csv is Y.train.pa; otu.qp.csv is Y.train.qp
rm(Y.train.qp, Y.train.pa, X.train, env.vars, otu.pa.csv, otu.qp.csv,P)

# gather all factor scores
str(modList[[1]]$ord$scores)
scoresList <- lapply(modList, function(x) x$ord$scores[,"Factor1"])

scores <- do.call(cbind, scoresList)
colnames(scores) <- sprintf("mod%01d", seq_along(modList))

# add to coordiantes
factor.sf <- S.train %>%
  cbind(scores) %>%
  sf::st_as_sf(coords = c("UTM_E", "UTM_N"), crs = 32610)

factor.sf

mv1 <- mapview(factor.sf, zcol = sprintf("mod%01d", seq_along(modList)),
              map.types = c("Esri.WorldImagery", "OpenStreetMap.HOT"),
              legend = T, hide = TRUE)

# hide not working with burst.. 
# mv2 <- mapview(factor.sf[, sprintf("mod%01d", seq_along(modList))], burst = TRUE, hide = TRUE,
#                map.types = c("Esri.WorldImagery", "OpenStreetMap.HOT"),
#                legend = T)
# mv2

## hide the layers by default.. modify leaflet object... 
mv1@map <- mv1@map %>% leaflet::hideGroup(group = sprintf("mod%01d", seq_along(modList))[-1])

mv1

mapshot(mv1, url = "Hmsc_CD/local/plots/factor_map.html", selfcontainted = TRUE) # moved manually from below
# mapshot(mv1, url = "factor_map.html", selfcontainted = TRUE)






# # get correlations with selected predictors
# (mod02.cor <- cor(mod02.ord$scores, site_res02[,cor.preds]))
# corrplot(cor(site_res02[,cor.preds]), 
#          method = "ellipse",
#          type = "lower",
#           mar=c(0,0,4,0))
# 
# corrplot(t(mod02.cor), is.corr = F,
#          method = "ellipse", cl.pos = "n")
# 
# dAIC <- AIC(mod01) - AIC(mod02) # will be generally positive  across species if mod2 is better... 
# boxplot(dAIC); abline(h =0, col = "red")




# png("Hmsc_CD/local/corplot_pa.png", width = 300, height = 200, units = "mm", res = 100)
# par(mfrow =c(1,6))
# t_corrplot(mod0.cor, "mod0")
# t_corrplot(mod01.cor, "mod01")
# t_corrplot(mod02.cor, "mod02")
# t_corrplot(mod03.cor, "mod03")
# t_corrplot(mod04.cor, "mod04")
# t_corrplot(mod05.cor, "mod05")
# dev.off()
# 
# dAIC <- list(mod0_mod01 = AIC(mod0)-AIC(mod01),
#              mod0_mod02 = AIC(mod0)-AIC(mod02),
#              mod0_mod03 = AIC(mod0)-AIC(mod03),
#              mod0_mod04 = AIC(mod0)-AIC(mod04),
#              mod0_mod05 = AIC(mod0)-AIC(mod05))
# 
# par(mfrow=c(1,1))
# png("Hmsc_CD/local/AIC_boxplot.png")
# boxplot(dAIC); abline(h = 0, col = "red", lty = 2, las = 2)
# dev.off()
# 
# png("Hmsc_CD/local/cor_boxplot.png")
# boxplot(list(cor0 = abs(mod0.cor),
#              cor1 = abs(mod01.cor),
#              cor2 = abs(mod02.cor),
#              cor3 = abs(mod03.cor),
#              cor4 = abs(mod04.cor),
#              cor5 = abs(mod05.cor)))
# dev.off()


# for results from 14/01/2020

fm <- list(as.formula(otu.pa ~  be500 + tri + insideHJA + lg_YrsDisturb),
           as.formula(otu.pa ~ be500 * oldGrowthIndex + tri + insideHJA + lg_YrsDisturb),
           as.formula(otu.pa ~ be500 * insideHJA + tri + oldGrowthIndex + lg_YrsDisturb),
           as.formula(otu.pa ~ be500 + tri + insideHJA + oldGrowthIndex + lg_YrsDisturb + mean.NDVI + lg_DistRoad + canopyHeight_m),
           as.formula(otu.pa ~ be500 * insideHJA + be500 * oldGrowthIndex + tri + lg_YrsDisturb + mean.NDVI + lg_DistRoad),
           as.formula(otu.pa ~ be10 + Nss + Ess + ht + cov2_4 + cov4_16 + ht.r1k + cov2_4.r1k + cov4_16.r1k + mTopo),
           as.formula(otu.pa ~ be10 + Nss + Ess + ht + cov2_4 + cov4_16 + ht.r500 + cov2_4.r500 + cov4_16.r500 + mTopo),
           as.formula(otu.pa ~ be10 + Nss + Ess + ht + cov2_4 + cov4_16 + ht.r250 + cov2_4.r250 + cov4_16.r250 + mTopo),
           as.formula(otu.pa ~ be500 + slope + twi + ht + cov2_4 + cov4_16 + ht.r500 + cov2_4.r500 + cov4_16.r500 + mTopo)
)

fm
