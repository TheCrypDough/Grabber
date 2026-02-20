"use client";

import { highlightCode } from "@ui/utils/shiki";
import { memo, useMemo, useEffect, useState } from "react";
import ReactMarkdown, { type Components } from "react-markdown";
import rehypeRaw from "rehype-raw";
import remarkGfm from "remark-gfm";
import type { BundledTheme } from "shiki";
import { MermaidBlock } from "./mermaid-block";

export interface MarkdownRendererProps {
  content: string;
  className?: string;
  /**
   * Shiki theme for code highlighting
   * @default "github-dark"
   */
  codeTheme?: BundledTheme;
  /**
   * Default language for code blocks without language specified
   * @default "bash"
   */
  defaultLanguage?: string;
}

/**
 * Standalone Markdown Renderer component with Shiki syntax highlighting
 * and Mermaid diagram support. Uses plain CSS (no Tailwind).
 */
export const MarkdownRenderer = memo(function MarkdownRenderer({
  content,
  className,
  codeTheme = "github-dark",
  defaultLanguage = "bash",
}: MarkdownRendererProps) {
  const markdownComponents: Components = useMemo(
    () => ({
      code: ({ className: codeClassName, children, ...props }) => {
        const match = /language-(\w+)/.exec(codeClassName || "");
        const language = match ? match[1] : "";
        // eslint-disable-next-line @typescript-eslint/no-base-to-string
        const codeString = String(children).replace(/\n$/, "");

        // Check if it's a code block (has newlines or language)
        const isBlock = codeString.includes("\n") || language || codeClassName;

        if (isBlock) {
          // Handle mermaid diagrams
          if (language === "mermaid") {
            return <MermaidBlock code={codeString} />;
          }

          return (
            <ShikiCodeBlock
              code={codeString}
              language={language || defaultLanguage}
              theme={codeTheme}
            />
          );
        }

        // Inline code
        return (
          <code {...props} className="grabber-markdown-inline-code">
            {children}
          </code>
        );
      },
      pre: ({ children }) => {
        // The pre tag is handled by the code component
        return <>{children}</>;
      },
      a: ({ href, children, ...props }) => (
        <a
          {...props}
          href={href}
          target="_blank"
          rel="noopener noreferrer"
          className="grabber-markdown-link"
        >
          {children}
        </a>
      ),
      img: ({ src, alt, ...props }) =>
        src && typeof src === "string" ? (
          <img
            {...props}
            src={src}
            alt={alt || ""}
            className="grabber-markdown-image"
            loading="lazy"
          />
        ) : null,
      p: ({ children }) => (
        <p className="grabber-markdown-paragraph">{children}</p>
      ),
      ul: ({ children }) => (
        <ul className="grabber-markdown-list grabber-markdown-ul">
          {children}
        </ul>
      ),
      ol: ({ children }) => (
        <ol className="grabber-markdown-list grabber-markdown-ol">
          {children}
        </ol>
      ),
      li: ({ children }) => (
        <li className="grabber-markdown-list-item">{children}</li>
      ),
      blockquote: ({ children }) => (
        <blockquote className="grabber-markdown-blockquote">
          {children}
        </blockquote>
      ),
      h1: ({ children }) => (
        <h1 className="grabber-markdown-heading grabber-markdown-h1">
          {children}
        </h1>
      ),
      h2: ({ children }) => (
        <h2 className="grabber-markdown-heading grabber-markdown-h2">
          {children}
        </h2>
      ),
      h3: ({ children }) => (
        <h3 className="grabber-markdown-heading grabber-markdown-h3">
          {children}
        </h3>
      ),
      h4: ({ children }) => (
        <h4 className="grabber-markdown-heading grabber-markdown-h4">
          {children}
        </h4>
      ),
      h5: ({ children }) => (
        <h5 className="grabber-markdown-heading grabber-markdown-h5">
          {children}
        </h5>
      ),
      h6: ({ children }) => (
        <h6 className="grabber-markdown-heading grabber-markdown-h6">
          {children}
        </h6>
      ),
      hr: () => <hr className="grabber-markdown-hr" />,
      table: ({ children }) => (
        <div className="grabber-markdown-table-wrapper">
          <table className="grabber-markdown-table">{children}</table>
        </div>
      ),
      thead: ({ children }) => (
        <thead className="grabber-markdown-thead">{children}</thead>
      ),
      tbody: ({ children }) => (
        <tbody className="grabber-markdown-tbody">{children}</tbody>
      ),
      tr: ({ children }) => <tr className="grabber-markdown-tr">{children}</tr>,
      th: ({ children }) => <th className="grabber-markdown-th">{children}</th>,
      td: ({ children }) => <td className="grabber-markdown-td">{children}</td>,
      strong: ({ children }) => (
        <strong className="grabber-markdown-strong">{children}</strong>
      ),
      em: ({ children }) => <em className="grabber-markdown-em">{children}</em>,
      del: ({ children }) => (
        <del className="grabber-markdown-del">{children}</del>
      ),
    }),
    [codeTheme, defaultLanguage],
  );

  return (
    <div className={`grabber-markdown-markdown ${className || ""}`}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeRaw]}
        components={markdownComponents}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
});

// ============================================================================
// ShikiCodeBlock - Internal component for code highlighting
// ============================================================================

interface ShikiCodeBlockProps {
  code: string;
  language: string;
  theme: BundledTheme;
}

const ShikiCodeBlock = memo(function ShikiCodeBlock({
  code,
  language,
  theme,
}: ShikiCodeBlockProps) {
  const [html, setHtml] = useState<string>("");

  useEffect(() => {
    let cancelled = false;

    highlightCode(code, language, theme).then((result) => {
      if (!cancelled) {
        setHtml(result);
      }
    });

    return () => {
      cancelled = true;
    };
  }, [code, language, theme]);

  return (
    <div className="grabber-markdown-code-block">
      {html ? (
        <div
          className="grabber-markdown-code-block-content"
          dangerouslySetInnerHTML={{ __html: html }}
        />
      ) : (
        <pre className="grabber-markdown-code-block-content grabber-markdown-code-block-fallback">
          <code>{code}</code>
        </pre>
      )}
    </div>
  );
});
