function plan = buildfile
%BUILDFILE Define quality checks, tests, and packaging for the SVAR toolbox.

import matlab.buildtool.tasks.CodeIssuesTask
import matlab.buildtool.tasks.TestTask

plan = buildplan(localfunctions);

plan("check") = CodeIssuesTask("tbx", InfoThreshold=0, WarningThreshold=0);

plan("test") = TestTask("tests/", ...
    SourceFiles="tbx/svar", ...
    TestResults="public/test-results.html", ...
    CodeCoverageResults=["public/coverage.html" "public/coverage.xml"]);

plan("package").Dependencies = ["check" "test"];
plan.DefaultTasks = "test";
end

function packageTask(~)
% Create a distributable toolbox archive after quality checks and tests pass.

v = ver('svar').Version;

if ~isfolder(releaseFolder)
    mkdir(releaseFolder)
end

options = matlab.addons.toolbox.ToolboxOptions( ...
    toolboxFolder, "c9f7fb11-f55a-4f4f-89c1-663dc7156107");
options.ToolboxName = "Structural Vector Autoregression Toolbox";
options.ToolboxVersion = v;
options.Summary = "Estimate and analyse structural vector autoregression models.";
options.Description = "Tools for estimating and analysing structural " + ...
    "vector autoregression models.";
options.OutputFile = fullfile(releaseFolder, "svar.mltbx");

matlab.addons.toolbox.packageToolbox(options)
end