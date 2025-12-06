#!/usr/bin/env node
/**
 * create_issues_bulk.js
 *
 * Creates two issues per student (React Web and React Native) in each student's repo,
 * but first checks existing issues to avoid duplicates (by title).
 *
 * Usage example (dry-run recommended first):
 *  GITHUB_TOKEN=ghp_xxx node create_issues_bulk.js \
 *    --owner=Uberhub-Mentorias \
 *    --repoPattern="autenticacao-{username}" \
 *    --students=students.txt \
 *    --dryRun
 *
 * Options:
 *  --owner           (required) org or owner for repos
 *  --repoPattern     (required) repo name pattern, use {username} placeholder
 *                    (for your case use: "autenticacao-{username}")
 *  --students        (required) CSV/TXT file with usernames (one per line), or CSV with header 'username'
 *  --token           GitHub token (or set env GITHUB_TOKEN)
 *  --dryRun          If true, do not actually create issues
 *  --commentExisting If true, add comment to existing matching issue instead of skipping
 *
 * Install deps:
 *  npm install @octokit/rest yargs csv-parse
 *
 */

const fs = require("fs");
const path = require("path");
const { Octokit } = require("@octokit/rest");
const yargs = require("yargs/yargs");
const { hideBin } = require("yargs/helpers");
const parse = require("csv-parse/lib/sync");

const argv = yargs(hideBin(process.argv))
	.option("owner", { type: "string", demandOption: true, describe: "Org or owner for repos" })
	.option("repoPattern", {
		type: "string",
		demandOption: true,
		describe: "Repo name pattern, use {username} placeholder",
	})
	.option("students", {
		type: "string",
		demandOption: true,
		describe: 'CSV/TXT file path with usernames (one per line or column "username")',
	})
	.option("token", { type: "string", describe: "GitHub token (or set env GITHUB_TOKEN)" })
	.option("dryRun", {
		type: "boolean",
		default: false,
		describe: "If true, do not actually create issues",
	})
	.option("commentExisting", {
		type: "boolean",
		default: false,
		describe: "If true, add comment to existing issue instead of skipping",
	}).argv;

const GITHUB_TOKEN = argv.token || process.env.GITHUB_TOKEN;
if (!GITHUB_TOKEN) {
	console.error("ERROR: Provide a GitHub token via --token or GITHUB_TOKEN env var.");
	process.exit(1);
}

const octokit = new Octokit({ auth: GITHUB_TOKEN });

function loadStudents(filePath) {
	const raw = fs.readFileSync(filePath, "utf8");
	// Try CSV parse; fallback to simple lines
	try {
		const records = parse(raw, { columns: true, skip_empty_lines: true });
		if (records.length > 0 && records[0].username !== undefined) {
			return records.map(r => r.username.trim()).filter(Boolean);
		}
		if (records.length > 0) {
			const firstCol = Object.keys(records[0])[0];
			return records.map(r => r[firstCol].trim()).filter(Boolean);
		}
	} catch (e) {
		// ignore and fallback to lines
	}
	return raw
		.split(/\r?\n/)
		.map(l => l.trim())
		.filter(Boolean)
		.filter(l => !l.startsWith("#"));
}

function loadTasks() {
	// Default tasks (two issues per student). Customize if needed.
	return [
		{
			id: "react-web",
			titleTemplate: "Entrega — React Web — @{username}",
			bodyTemplate: `Olá @{username},

Esta issue registra sua submissão da tarefa React (Web).

Instruções:
- Branch de submissão sugerida: students/{username}/react-web
- Abra um PR para main e cole o link aqui.

Checklist:
- Código compila
- Testes passam localmente
- README (react-web/README.md) atualizado
`,
			labels: ["task:react-web", "status:submitted"],
		},
		{
			id: "react-mobile",
			titleTemplate: "Entrega — React Mobile — @{username}",
			bodyTemplate: `Olá @{username},

Esta issue registra sua submissão da tarefa React Native.

Instruções:
- Branch de submissão sugerida: students/{username}/react-mobile
- Abra um PR para main e cole o link aqui.

Checklist:
- Código compila (se aplicável)
- Testes passam localmente
- README (react-mobile/README.md) atualizado
`,
			labels: ["task:react-mobile", "status:submitted"],
		},
	];
}

async function repoExists(owner, repo) {
	try {
		await octokit.repos.get({ owner, repo });
		return true;
	} catch (err) {
		return false;
	}
}

async function findExistingIssue(owner, repo, title) {
	// Use pagination to get all issues (open + closed)
	const issues = await octokit.paginate(octokit.issues.listForRepo, {
		owner,
		repo,
		state: "all",
		per_page: 100,
	});
	// Try exact title match first
	const byTitle = issues.find(i => i.title && i.title.trim() === title.trim());
	if (byTitle) return byTitle;
	// Fallback: try title contains (case-insensitive)
	const lower = title.toLowerCase();
	return issues.find(i => i.title && i.title.toLowerCase().includes(lower));
}

(async () => {
	const students = loadStudents(argv.students);
	if (students.length === 0) {
		console.error("No students found in file:", argv.students);
		process.exit(1);
	}
	const tasks = loadTasks();

	console.log(
		`Found ${students.length} students, ${tasks.length} tasks. dryRun=${argv.dryRun} commentExisting=${argv.commentExisting}`
	);
	for (const username of students) {
		const repoName = argv.repoPattern.replace(/{username}/g, username);
		const owner = argv.owner;
		const repoFull = `${owner}/${repoName}`;
		// Check repo exists
		const exists = await repoExists(owner, repoName);
		if (!exists) {
			console.warn(`Skipping ${repoFull}: repository not found or inaccessible.`);
			continue;
		}
		for (const task of tasks) {
			const title = task.titleTemplate.replace(/\{username\}/g, username);
			const body = task.bodyTemplate
				.replace(/\{username\}/g, username)
				.replace(/\{branchReactWeb\}/g, `students/${username}/react-web`)
				.replace(/\{branchReactNative\}/g, `students/${username}/react-mobile`)
				.replace(/react-native\/README\.md/g, "react-mobile/README.md");
			const labels = task.labels || [];

			// Check for existing issue
			let existing = null;
			try {
				existing = await findExistingIssue(owner, repoName, title);
			} catch (err) {
				console.warn(`Warning: could not list issues for ${repoFull}: ${err.message}`);
			}

			if (existing) {
				console.log(
					`[skip] ${repoFull} -> existing issue #${existing.number} title="${existing.title}"`
				);
				if (!argv.dryRun && argv.commentExisting) {
					try {
						await octokit.issues.createComment({
							owner,
							repo: repoName,
							issue_number: existing.number,
							body: `Bot: tentativa de criar issue duplicada detectada. Se for necessário, atualize esta issue ou remova duplicatas.`,
						});
						console.log(` -> commented on existing issue #${existing.number}`);
					} catch (err) {
						console.warn(`Failed to comment on existing issue #${existing.number}: ${err.message}`);
					}
				}
				continue;
			}

			console.log(`${argv.dryRun ? "[dry-run]" : "[create]"} ${repoFull} -> Issue: ${title}`);
			if (!argv.dryRun) {
				try {
					await octokit.issues.create({
						owner,
						repo: repoName,
						title,
						body,
						labels,
					});
					// small delay to avoid hitting rate limits in large batches
					await new Promise(r => setTimeout(r, 200));
				} catch (err) {
					console.error(`Failed to create issue on ${repoFull}: ${err.message}`);
				}
			}
		}
	}
	console.log("Done.");
})();
