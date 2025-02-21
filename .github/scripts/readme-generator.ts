import fs from 'fs';

type App = {
  id: string;
  name: string;
  dockerImage: string;
  version: string;
  youtubeVideo: string;
  docs: string;
};

const getAppsList = async () => {
  const apps: Record<string, App> = {};
  const res = await fetch(
    "https://api.github.com/repos/bigbeartechworld/big-bear-docker-images/contents/Apps"
  );

  if (!res.ok) {
    console.error(`Failed to fetch app list, status: ${res.status}`);
    return { apps };
  }

  const data = await res.json();
  const appNames = data.map((app) => app.name);

  for (const app of appNames) {
    if (app === "__tests__") continue;

    const configUrl = `https://raw.githubusercontent.com/bigbeartechworld/big-bear-docker-images/main/Apps/${app}/config.json`;
    const configRes = await fetch(configUrl);

    if (!configRes.ok) {
      console.error(
        `Failed to fetch config for ${app}, status: ${configRes.status}`
      );
      continue;
    }

    try {
      const appConfig = await configRes.json();
      apps[app] = {
        id: appConfig.id || "N/A",
        name: appConfig.name || "N/A",
        dockerImage: appConfig.image || "N/A",
        version: appConfig.version || "N/A",
        youtubeVideo: appConfig.youtube || "",
        docs: appConfig.docs_link || "",
      };
    } catch (e) {
      console.error(`Error parsing config for ${app}: ${e.message}`);
    }
  }

  return { apps };
};

const appToMarkdownTable = (apps: Record<string, App>) => {
  let table = `| Application | Docker Image | Version | YouTube Video | Docs |\n`;
  table += `| --- | --- | --- | --- | --- |\n`;

  Object.values(apps).forEach((app) => {
    const youtubeLink = app.youtubeVideo
      ? `[YouTube Video](${app.youtubeVideo})`
      : "";
    const docsLink = app.docs ? `[Docs](${app.docs})` : "";

    table += `| ${app.name} | ${app.dockerImage} | ${app.version} | ${youtubeLink} | ${docsLink} |\n`;
  });

  return table;
};

const writeToReadme = (appsTable) => {
  const baseReadme = fs.readFileSync(
    __dirname + "/../../templates/README.md",
    "utf8"
  );
  const finalReadme = baseReadme.replace("<!appsList>", appsTable);
  fs.writeFileSync(__dirname + "/../../README.md", finalReadme);
};

const main = async () => {
  const apps = await getAppsList();
  const markdownTable = appToMarkdownTable(apps.apps);
  writeToReadme(markdownTable);
};

main();
