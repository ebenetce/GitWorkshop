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

plan("package").Dependencies = ["check" "test" "doc"];
plan.DefaultTasks = "test";
end

function docTask(~)
% Build HTML documentation and the MATLAB Help browser index.

if isempty(ver('docmaker'))
    websave('MATLAB_DocMaker.mltbx','https://github.com/mathworks/docmaker/releases/latest/download/MATLAB_DocMaker.mltbx');
    cobj = onCleanup(@() delete('MATLAB_DocMaker.mltbx'));
    matlab.addons.install('MATLAB_DocMaker.mltbx', true);
end

doc = fullfile( currentProject().RootFolder, "tbx", "doc" );

docdelete(doc)

md = fullfile(doc,"**","*.md"); % Markdown documents

websave(fullfile('tbx','doc','mathjax-config.js'),'https://raw.githubusercontent.com/mathworks/docmaker/refs/heads/master/tbx/docmaker/resources/mathjax-config.js')
html = docconvert(md, Scripts = fullfile(doc, 'mathjax-config.js')); % convert to HTML

docrun(html) % run code and insert output
docindex(doc); % index

end

function packageTask(~)
% Create a distributable toolbox archive after quality checks and tests pass.

projectRoot = fileparts(mfilename("fullpath"));
toolboxFolder = fullfile(projectRoot, "tbx");
releaseFolder = fullfile(projectRoot, "releases");
v = toolboxVersion(fullfile(toolboxFolder, "svar"));

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

function version = toolboxVersion(toolboxFolder)
% Read the toolbox version declared in Contents.m.

contentsText = fileread(fullfile(toolboxFolder, "Contents.m"));
versionTokens = regexp(contentsText, "Version\s+(\d+\.\d+\.\d+)", ...
    "tokens", "once");

if isempty(versionTokens)
    error("svar:build:MissingVersion", ...
        "Add a 'Version major.minor.patch' line to tbx/svar/Contents.m.")
end

version = string(versionTokens{1});
end
