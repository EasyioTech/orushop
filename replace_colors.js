const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) { 
            results = results.concat(walk(file));
        } else { 
            if (file.endsWith('.dart')) results.push(file);
        }
    });
    return results;
}

const files = walk('lib');

const replacements = [
    { regex: /Colors\.grey\.shade50/g, replacement: 'AppTheme.slate50' },
    { regex: /Colors\.grey\[50\]!?/g, replacement: 'AppTheme.slate50' },
    { regex: /Colors\.grey\.shade100/g, replacement: 'AppTheme.slate100' },
    { regex: /Colors\.grey\[100\]!?/g, replacement: 'AppTheme.slate100' },
    { regex: /Colors\.grey\.shade200/g, replacement: 'AppTheme.slate200' },
    { regex: /Colors\.grey\[200\]!?/g, replacement: 'AppTheme.slate200' },
    { regex: /Colors\.grey\.shade300/g, replacement: 'AppTheme.slate300' },
    { regex: /Colors\.grey\[300\]!?/g, replacement: 'AppTheme.slate300' },
    { regex: /Colors\.grey\.shade400/g, replacement: 'AppTheme.slate400' },
    { regex: /Colors\.grey\[400\]!?/g, replacement: 'AppTheme.slate400' },
    { regex: /Colors\.grey\.shade500/g, replacement: 'AppTheme.slate500' },
    { regex: /Colors\.grey\[500\]!?/g, replacement: 'AppTheme.slate500' },
    { regex: /Colors\.grey\.shade600/g, replacement: 'AppTheme.slate600' },
    { regex: /Colors\.grey\[600\]!?/g, replacement: 'AppTheme.slate600' },
    { regex: /Colors\.grey\b(?!\.)/g, replacement: 'AppTheme.slate500' },
    { regex: /Colors\.black87/g, replacement: 'AppTheme.textPrimary' },
    { regex: /Colors\.black54/g, replacement: 'AppTheme.textSecondary' },
    { regex: /Colors\.black45/g, replacement: 'AppTheme.slate500' },
    { regex: /Colors\.black26/g, replacement: 'AppTheme.slate400' },
    { regex: /Colors\.black12/g, replacement: 'AppTheme.slate200' },
    { regex: /Colors\.black\b/g, replacement: 'AppTheme.primaryDark' },
    { regex: /Colors\.red\.shade50/g, replacement: 'AppTheme.errorColor.withValues(alpha: 0.1)' },
    { regex: /Colors\.red\[50\]!?/g, replacement: 'AppTheme.errorColor.withValues(alpha: 0.1)' },
    { regex: /Colors\.redAccent/g, replacement: 'AppTheme.errorColor' },
    { regex: /Colors\.red\b/g, replacement: 'AppTheme.errorColor' },
    { regex: /Colors\.green\.shade50/g, replacement: 'AppTheme.successColor.withValues(alpha: 0.1)' },
    { regex: /Colors\.green\[50\]!?/g, replacement: 'AppTheme.successColor.withValues(alpha: 0.1)' },
    { regex: /Colors\.green\b/g, replacement: 'AppTheme.successColor' },
    { regex: /Colors\.orange\.shade50/g, replacement: 'AppTheme.warningColor.withValues(alpha: 0.1)' },
    { regex: /Colors\.orange\[50\]!?/g, replacement: 'AppTheme.warningColor.withValues(alpha: 0.1)' },
    { regex: /Colors\.orange\.shade200/g, replacement: 'AppTheme.warningColor.withValues(alpha: 0.3)' },
    { regex: /Colors\.orange\[200\]!?/g, replacement: 'AppTheme.warningColor.withValues(alpha: 0.3)' },
    { regex: /Colors\.orange\.shade700/g, replacement: 'AppTheme.warningColor' },
    { regex: /Colors\.orange\[700\]!?/g, replacement: 'AppTheme.warningColor' },
    { regex: /Colors\.orange\b/g, replacement: 'AppTheme.warningColor' },
    { regex: /Colors\.blue\b/g, replacement: 'AppTheme.accentColor' },
    { regex: /Colors\.cyan\b/g, replacement: 'AppTheme.accentColor' }
];

let changedFiles = 0;

files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    let original = content;
    
    replacements.forEach(r => {
        content = content.replace(r.regex, r.replacement);
    });
    
    if (content !== original) {
        if (!content.includes("import 'package:orushops/core/theme/app_theme.dart';") && 
            !content.includes("class AppTheme")) {
            // Need to add AppTheme import
            const importMatch = content.match(/import 'package:[^']+';\n/g);
            if (importMatch) {
                const lastImport = importMatch[importMatch.length - 1];
                content = content.replace(lastImport, lastImport + "import 'package:orushops/core/theme/app_theme.dart';\n");
            } else if (content.includes("import 'package:flutter/material.dart';")) {
                content = content.replace("import 'package:flutter/material.dart';\n", "import 'package:flutter/material.dart';\nimport 'package:orushops/core/theme/app_theme.dart';\n");
            } else {
                content = "import 'package:orushops/core/theme/app_theme.dart';\n" + content;
            }
        }
        
        fs.writeFileSync(file, content, 'utf8');
        changedFiles++;
        console.log('Updated', file);
    }
});

console.log('Total files changed:', changedFiles);
