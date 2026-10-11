file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- normalizePath(file.path(dirname(file), ".."), winslash = "/")
source(file.path(root, "R", "paths.R"))
source(file.path(root, "R", "features.R"))
args <- read_args(list("data-dir" = file.path(root, "data"),
  "output-dir" = file.path(root, "artifacts", "cv"), "library" = file.path(root, ".R-library")))
load_packages(args[["library"]])
invisible(Sys.setlocale("LC_COLLATE", "C"))

train <- read_data(args[["data-dir"]], "train")
stopifnot(!anyNA(train$SalePrice), all(train$SalePrice > 0))
train_x <- add_features(train)
log_price <- log(train$SalePrice)

make_folds <- function(n, k, seed) {
  set.seed(seed)
  sample(rep(seq_len(k), length.out = n))
}
tree_grid <- expand.grid(depth = c(4L, 6L), l2_leaf_reg = c(3, 10))
param_grid <- merge(transform(tree_grid, tree_id = seq_len(nrow(tree_grid))),
  data.frame(iterations = c(500L, 1000L, 2000L)), by = NULL)
cat_params <- function(tree, rounds, seed) {
  list(loss_function = "RMSE", eval_metric = "RMSE", iterations = rounds,
    depth = tree_grid$depth[tree], l2_leaf_reg = tree_grid$l2_leaf_reg[tree],
    learning_rate = .03, max_ctr_complexity = 1L, random_seed = seed,
    thread_count = 2L, logging_level = "Silent", allow_writing_files = FALSE)
}

outer_folds <- make_folds(nrow(train_x), 5, 20273001)
oof_pred <- rep(NA_real_, nrow(train_x))
chosen_params <- list()
create_output(args[["output-dir"]])

for (fold in 1:5) {
  train_rows <- which(outer_folds != fold)
  valid_rows <- which(outer_folds == fold)
  seed <- 20281000 + fold
  inner_folds <- make_folds(length(train_rows), 3, seed)
  inner_pred <- matrix(NA_real_, length(train_rows), nrow(param_grid))

  for (inner_fold in 1:3) {
    fit_rows <- train_rows[inner_folds != inner_fold]
    val_rows <- train_rows[inner_folds == inner_fold]
    prep <- fit_preprocess(train_x[fit_rows, ])
    train_pool <- catboost::catboost.load_pool(prep_data(train_x[fit_rows, ], prep),
      label = log_price[fit_rows])
    valid_pool <- catboost::catboost.load_pool(prep_data(train_x[val_rows, ], prep))

    for (tree in seq_len(nrow(tree_grid))) {
      model <- catboost::catboost.train(train_pool, params = cat_params(tree, 2000L, seed + inner_fold))
      for (choice in which(param_grid$tree_id == tree)) {
        inner_pred[inner_folds == inner_fold, choice] <- catboost::catboost.predict(
          model, valid_pool, ntree_end = param_grid$iterations[choice])
      }
    }
    cat("Fold", fold, "inner fold", inner_fold, "done\n")
  }

  cv_scores <- param_grid
  cv_scores$log_mse <- colMeans((inner_pred - log_price[train_rows])^2)
  best_params <- cv_scores[which.min(cv_scores$log_mse), ]
  write.csv(cv_scores, file.path(args[["output-dir"]], paste0("fold_", fold, ".csv")), row.names = FALSE)

  prep <- fit_preprocess(train_x[train_rows, ])
  train_pool <- catboost::catboost.load_pool(prep_data(train_x[train_rows, ], prep),
    label = log_price[train_rows])
  model <- catboost::catboost.train(train_pool,
    params = cat_params(best_params$tree_id, best_params$iterations, 20282000 + fold))
  valid_pool <- catboost::catboost.load_pool(prep_data(train_x[valid_rows, ], prep))
  oof_pred[valid_rows] <- catboost::catboost.predict(model, valid_pool)
  chosen_params[[fold]] <- data.frame(fold = fold, best_params)
}

stopifnot(all(is.finite(oof_pred)))
metrics <- data.frame(model = "CatBoost", log_mse = mean((oof_pred - log_price)^2),
  log_rmse = sqrt(mean((oof_pred - log_price)^2)))
write.csv(metrics, file.path(args[["output-dir"]], "metrics.csv"), row.names = FALSE)
write.csv(do.call(rbind, chosen_params), file.path(args[["output-dir"]], "params.csv"), row.names = FALSE)
write.csv(data.frame(Id = train$Id, fold = outer_folds, actual_log = log_price, predicted_log = oof_pred),
  file.path(args[["output-dir"]], "oof.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(args[["output-dir"]], "session.txt"))
print(metrics, row.names = FALSE)
