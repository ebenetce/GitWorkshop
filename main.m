%MAIN Replicate the reduced-form posterior in Arias, Rubio-Ramirez, and
%Waggoner (2023), "Uniform Priors for Impulse Responses."
%
% The paper's application uses a 4-variable VAR(4) for 1984Q1--2007Q4 and
% a prior that is uniform over the joint vector of impulse responses. The
% uniformirbvarm object implements its implied reduced-form NIW prior.
%
% The paper's figures additionally condition on sign and zero restrictions
% and Haar rotations. Those identification methods are not yet part of the
% toolbox. The figures below are therefore recursive Cholesky diagnostics
% for the paper's reduced-form posterior, not reproductions of its
% restricted-rotation impulse-response figures.
%
% See also UNIFORMIRBVARM, SVAR.IRF, SVAR.FEVD, SVAR.VARMFROMCOEFFICIENTS.

clear
clc

%% Settings
numLags = 4;
irfHorizon = 20;
fevdHorizon = 20;
numPosteriorDraws = 5000;
drawBatchSize = 1000;
randomSeed = 0;

sampleStart = datetime(1984, 1, 1);
sampleEnd = datetime(2007, 10, 1);

%% Data
loadedData = load("data.mat");
paperSample = loadedData.data(timerange(sampleStart, sampleEnd, "closed"), :);
responses = paperSample.Variables;
seriesNames = string(paperSample.Properties.VariableNames);
[numObservations, numSeries] = size(responses);
numEffectiveObservations = numObservations - numLags;

fprintf("Sample: %s to %s (%d observations, %d effective)\n", ...
    string(sampleStart), string(sampleEnd), numObservations, ...
    numEffectiveObservations);

%% Uniform impulse-response reduced-form posterior
prior = uniformirbvarm(numSeries, numLags, SeriesNames=seriesNames, ...
    DeterminantShift=-3);
posterior = estimate(prior, responses, Display="off");
pointVAR = bvar2var(posterior);

paperDeterminantNumerator = prior.NumEquationCoefficients ...
    + prior.DeterminantShift;
expectedPosteriorDoF = numEffectiveObservations + prior.DoF;

assert(prior.NumEquationCoefficients == numSeries*numLags + 1, ...
    "The VAR coefficient count does not match the paper's VAR(4) with intercept.");
assert(prior.LogDetExponent == paperDeterminantNumerator/2, ...
    "The reduced-form determinant exponent is inconsistent with the prior.");
assert(posterior.DoF == expectedPosteriorDoF, ...
    "Posterior DoF does not match the reduced-form formula.");

fprintf("Model: n = %d, p = %d, k = %d\n", ...
    numSeries, numLags, prior.NumEquationCoefficients);
fprintf("Uniform-IR prior: a = %g, log-determinant exponent = %g\n", ...
    paperDeterminantNumerator, prior.LogDetExponent);
fprintf("Prior DoF = %g, posterior DoF = %g\n\n", ...
    prior.DoF, posterior.DoF);

%% Posterior draws and stability conditioning
% The paper retains draws satisfying stability and its sign/zero
% restrictions. The latter require a dedicated Haar-rotation identification
% routine, so this script imposes only the reduced-form stability condition.
rng(randomSeed, "twister");
irfDraws = zeros(irfHorizon + 1, numSeries, numSeries, ...
    numPosteriorDraws);
numAcceptedDraws = 0;
numCandidateDraws = 0;

while numAcceptedDraws < numPosteriorDraws
    [coefficientDraws, covarianceDraws] = simulate(posterior, ...
        NumDraws=drawBatchSize);
    numCandidateDraws = numCandidateDraws + drawBatchSize;

    for draw = 1:drawBatchSize
        drawVAR = svar.varmFromCoefficients(posterior, ...
            reshape(coefficientDraws(:, draw), [], numSeries), ...
            covarianceDraws(:, :, draw));

        if max(abs(eig(svar.companionMatrix(drawVAR)))) >= 1
            continue
        end

        % Recursive ordering: output per capita, hours per capita, GDP deflator,
        % and the long rate. This is only a diagnostic identification.
        drawImpact = chol(covarianceDraws(:, :, draw), "lower");
        numAcceptedDraws = numAcceptedDraws + 1;
        irfDraws(:, :, :, numAcceptedDraws) = svar.irf(drawVAR, drawImpact, ...
            irfHorizon);

        if numAcceptedDraws == numPosteriorDraws
            break
        end
    end
end

fprintf("Retained %d stable draws from %d posterior draws.\n\n", ...
    numAcceptedDraws, numCandidateDraws);

%% Recursive impulse-response diagnostic
% The point estimate and 68 percent bands use the same recursive ordering
% as the posterior draws above. They are not the paper's sign/zero-
% restricted Figure 3 bands.
pointImpact = chol(pointVAR.Covariance, "lower");
pointIRF = svar.irf(pointVAR, pointImpact, irfHorizon);
irfBand = quantile(irfDraws, [0.16 0.84], 4);
horizons = 0:irfHorizon;

figure(Color="w", Name="Uniform-IR posterior: recursive IRFs");
layout = tiledlayout(numSeries, numSeries, TileSpacing="compact", ...
    Padding="compact");

for response = 1:numSeries
    for shock = 1:numSeries
        ax = nexttile(layout);
        lowerBand = irfBand(:, response, shock, 1);
        upperBand = irfBand(:, response, shock, 2);

        fill(ax, [horizons fliplr(horizons)], ...
            [lowerBand; flipud(upperBand)].', [0.86 0.89 0.95], ...
            EdgeColor="none");
        hold(ax, "on");
        plot(ax, horizons, pointIRF(:, response, shock), "k", ...
            LineWidth=1.1);
        yline(ax, 0, ":", Color=[0.45 0.45 0.45]);
        xlim(ax, [horizons(1) horizons(end)]);
        box(ax, "on");

        if response == 1
            title(ax, "Recursive shock " + shock);
        end
        if shock == 1
            ylabel(ax, seriesNames(response));
        end
        if response == numSeries
            xlabel(ax, "Quarters");
        end
    end
end

title(layout, [ ...
    "Uniform-IR posterior: recursive diagnostic IRFs (68% bands)", ...
    "Not the paper's sign/zero-restricted identification"]);

%% Recursive forecast-error variance diagnostic
% Reuse the point model and impact matrix through the toolbox FEVD routine.
pointFEVD = svar.fevd(pointVAR, pointImpact, fevdHorizon);
fevdHorizons = 0:fevdHorizon;

figure(Color="w", Name="Uniform-IR posterior: recursive FEVD");
layout = tiledlayout(2, 2, TileSpacing="compact", Padding="compact");

for response = 1:numSeries
    ax = nexttile(layout);
    plot(ax, fevdHorizons, squeeze(pointFEVD(:, response, :)), ...
        LineWidth=1.1);
    ylim(ax, [0 1]);
    xlim(ax, [fevdHorizons(1) fevdHorizons(end)]);
    yline(ax, 0, ":", Color=[0.45 0.45 0.45]);
    box(ax, "on");
    title(ax, seriesNames(response));
    xlabel(ax, "Quarters");
    ylabel(ax, "Variance share");

    if response == 1
        legend(ax, "Recursive shock " + (1:numSeries), ...
            Location="eastoutside");
    end
end

title(layout, [ ...
    "Uniform-IR posterior: recursive diagnostic FEVD", ...
    "Not the paper's sign/zero-restricted identification"]);

%% Replication gap
fprintf("Replication gap:\n");
fprintf("  * The paper's Figure 3--5 results require sign and zero restrictions,\n");
fprintf("    Haar rotations, and joint credible-set construction.\n");
fprintf("  * This script reproduces the paper's data and uniform-IR reduced-form\n");
fprintf("    posterior, then plots recursive diagnostics from that posterior.\n");
