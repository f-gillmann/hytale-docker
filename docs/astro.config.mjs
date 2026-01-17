// @ts-check
import {defineConfig} from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
    site: 'https://f-gillmann.github.io',
    base: '/hytale-docker',
    integrations: [
        starlight({
            title: 'Hytale Docker',
            social: [{icon: 'github', label: 'GitHub', href: 'https://github.com/f-gillmann/hytale-docker'}],
            sidebar: [
                {
                    label: "Getting Started",
                    link: "/",
                },
                {
                    label: "Reference",
                    autogenerate: {
                        directory: "reference",
                    }
                },
                {
                    label: "Guides",
                    autogenerate: {
                        directory: "guides",
                    }
                },
                {
                    label: "Official Hytale Resources",
                    items: [
                        {
                            label: "Hytale Server Manual",
                            link: "https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual",
                        },
                        {
                            label: "Server Provider Auth Guide",
                            link: "https://support.hytale.com/hc/en-us/articles/45328341414043-Server-Provider-Authentication-Guide",
                        },
                    ],
                },
            ],
        }),
    ],
});
