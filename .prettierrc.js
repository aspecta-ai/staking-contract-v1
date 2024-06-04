module.exports = {
    printWidth: 80,
    tabWidth: 4,
    trailingComma: 'all',
    singleQuote: true,
    semi: true,
    importOrder: ['^@core/(.*)$', '^@server/(.*)$', '^@ui/(.*)$', '^[./]'],
    importOrderSeparation: true,
    importOrderSortSpecifiers: true,
    plugins: [
        '@trivago/prettier-plugin-sort-imports',
        'prettier-plugin-solidity',
    ],
    overrides: [
        {
            files: '*.sol',
            options: {
                parser: 'solidity-parse',
                printWidth: 80,
                tabWidth: 4,
                useTabs: false,
                singleQuote: false,
                bracketSpacing: false,
            },
        },
    ],
};
