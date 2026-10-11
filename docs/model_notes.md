# Model notes

The final CatBoost submission scored **0.12062**, with a recorded rank of **391**. The score and ranking screenshots are in `evidence/`. About top 10% is an estimate using a team count from an earlier screenshot; it is not a medal or a final ranking.

The model uses the original housing variables plus age, remodel age, total floor area, bathroom counts, facility flags, quality × area and three log-area features. Half bathrooms count as 0.5. Missing parts of a total remain missing rather than being treated as zero.

Within each fitting fold, numeric values are filled with the fold's median and a missingness flag is added. Categorical values are passed as factors. Missing categories use a separate token. None of these statistics is fitted using validation or test data.

The search compared depths 4/6, L2 regularization 3/10 and 500/1,000/2,000 trees. Learning rate was 0.03. Five outer folds assessed models selected by three-fold inner CV. The final seed is 20284000.

Local log RMSE was 0.121887 for CatBoost and 0.125826 for the cached earlier blend on the same outer folds. The blend had a different tuning budget, and these folds had already been used in development. This was an exploratory comparison.

The local improvement was uneven. Excluding the two preidentified houses 524 and 1299, CatBoost's RMSE was 0.116119 against 0.113970 for the blend. Those reduced-row figures are only diagnostics; every house remains in the main evaluation.

An earlier holdout was inspected repeatedly and was later retired as an independent test. Several earlier experiments had small average gains that did not hold up across splits. The final repo focuses on the CatBoost model rather than bundling every trial.

Predictions are exponentiated log prices. They are not guaranteed to be unbiased estimates of the conditional mean dollar price. Public-answer lookup experiments from the private workspace are not included or used here.
