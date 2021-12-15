\NeedsTeXFormat{LaTeX2e}
\RequirePackage{ expl3 , l3keys2e }
\RequirePackage{xparse}

\ProvidesExplClass
  {internet}
  {2013/06/10}
  {1}
  {}

\file_input:n {internetmodes.code.tex}

\seq_new:N \l__txt_files_seq
\seq_new:N \l__txt_mfiles_seq
\seq_new:N \l__txt_lfiles_seq
\tl_new:N \l__txt_out_tl
\tl_new:N \l__txt_class_tl
\prop_new:N \l__txt_popts_prop
\clist_new:N \l__txt_copts_clist

\group_begin:
\char_set_lccode:nn {`;}{`_}
\tex_lowercase:D {
\group_end:
\tl_set:Nn \l__txt_underscore_tl {;}
}

\group_begin:
\char_set_lccode:nn {`;}{`^}
\tex_lowercase:D {
\group_end:
\tl_set:Nn \l__txt_caret_tl {;}
}

\group_begin:
\char_set_lccode:nn {`;}{`&}
\tex_lowercase:D {
\group_end:
\tl_set:Nn \l__txt_amp_tl {;}
}

\tl_set:Nn \l__txt_class_tl {article}

\cs_new_nopar:Npn \tl_split_at:NnNN #1#2#3#4
{
  \cs_set:Npn \tl_split_at_aux:w ##1 #2 ##2 \q_stop
  {
    \tl_set:Nn #3 {##1}
    \tl_set:Nn #4 {##2}
  }
  \exp_last_unbraced:NV \tl_split_at_aux:w #1 \q_stop
}

\cs_new:Npn \txt_add_option:nn #1#2
{
  \prop_get:NnNTF \l__txt_popts_prop {#1} \l_tmpa_clist
  {
    \clist_put_right:Nn \l_tmpa_clist {#2}
    \prop_put:NnV \l__txt_popts_prop {#1} \l_tmpa_clist
  }
  {
    \prop_put:Nnn \l__txt_popts_prop {#1} {#2}
  }
}


\cs_generate_variant:Nn \tl_split_at:NnNN {NVNN}
\cs_generate_variant:Nn \tl_if_in:NnTF {NV}
\cs_generate_variant:Nn \tl_if_in:NnT {NV}
\cs_generate_variant:Nn \keys_if_exist:nnT {nV}

  \keys_define:nn {internet options} {
    text .bool_set:N = \l__txt_text_bool,
    doc .bool_set_inverse:N = \l__txt_text_bool,
    files to load .code:n = {
      \seq_put_right:Nn \l__txt_files_seq {#1}
    },
    maths to load .code:n = {
      \seq_put_right:Nn \l__txt_mfiles_seq {#1}
    },
    output mode .tl_set:N = \l__txt_out_tl,
    class .tl_set:N = \l__txt_class_tl,
    use filename .code:n = {
      \tl_set_eq:NN \l_tmpb_tl \c_sys_jobname_str
      \tl_if_in:NVT \l_tmpb_tl \l__txt_underscore_tl
      {
        \tl_split_at:NVNN \l_tmpb_tl \l__txt_underscore_tl \l_tmpa_tl \l_tmpb_tl
        
        \bool_set_true:N \l_tmpa_bool
        \bool_do_while:Nn \l_tmpa_bool {
          \tl_if_in:NVTF \l_tmpb_tl \l__txt_underscore_tl
          {
            \tl_split_at:NVNN \l_tmpb_tl \l__txt_underscore_tl \l_tmpa_tl \l_tmpb_tl
          }
          {
            \bool_set_false:N \l_tmpa_bool
          }

          \keys_if_exist:nVT {internet options} \l_tmpa_tl
          {
            \keys_set:nV {internet options} \l_tmpa_tl
          }
        }
        \keys_if_exist:nVT {internet options} \l_tmpb_tl
        {
          \keys_set:nV {internet options} \l_tmpb_tl
        }
      }
    },
    epub .meta:n = {
      output mode = epub,
      files to load = epub,
      options = {epub}{#1},
    },
    pandoc .meta:n = {
      output mode = pandoc,
      files to load = pandoc,
      options = {pandoc}{#1},
    },
    xhtml .meta:n = {
      output mode = xhtml,
      files to load = xhtml,
      options = {xhtml}{#1},
      options = {mathml}{container=xhtm},
    },
    html5 .meta:n = {
      output mode = html5,
      files to load = html5,
      options = {html5}{#1},
      options = {mathml}{container=htmv},
    },
    itex .meta:n ={
      maths to load = itex,
      options = {itex}{#1},
    },
    basic maths .meta:n ={
      maths to load = basicmaths,
      options = {basicmaths}{#1},
    },
    mathml .meta:n ={
      maths to load = mathml,
      options = {mathml}{#1},
    },
    mathjax .meta:n ={
      maths to load = mathjax,
      options = {mathjax}{#1},
    },
    instiki .meta:n = {
      output mode = instiki,
      files to load = instiki,
      maths to load = itex,
      options = {instiki}{#1},
    },
    maruku .meta:n = {
      output mode = maruku,
      files to load = maruku,
      options = {maruku}{#1},
    },
    markdown .meta:n = {
      output mode = markdown,
      files to load = markdown,
      options = {markdown}{#1},
    },
    github .meta:n = {
      output mode = github,
      files to load = github,
      options = {github}{#1},
    },
    markdownextra .meta:n = {
      output mode = markdownextra,
      files to load = markdownextra,
      options = {markdownextra}{#1},
    },
    emoji .meta:n = {
      files to load = emoji
    },
    options .code:n = {
      \txt_add_option:nn #1
    },
    unknown .code:n = {
      \tl_if_empty:nTF {#1} 
      {
        \clist_put_right:Nx \l__txt_copts_clist {\l_keys_key_tl}
      }
      {
        \clist_put_right:Nx \l__txt_copts_clist {\l_keys_key_tl=#1}
      }
    },
    
  }


\ProcessKeysOptions{internet options}

\tl_set_eq:NN \@classoptionslist \l__txt_copts_clist

\bool_if:nTF \l__txt_text_bool
{
  \file_input:n {internettext.code.tex}
}
{
  \LoadClass[\l__txt_copts_clist]{\l__txt_class_tl}
}

\cs_new:Npn \txt_try_options:nnn #1#2#3
{
  \clist_map_inline:nn {#1}
  {
    \keys_if_exist:nnT {##1 options} {#2}
    {
      \tl_if_empty:nTF {#3}
      {
        \keys_set:nV {##1 options} {#2}
      }
      {
        \keys_set:nV {##1 options} {#2 = #3}
      }
      \clist_map_break:
    }
  }
}

\msg_new:nnnn {text} {no~ file} {Module~ '#1'~ not~ available~ to~ load~ at~ line~ \msg_line_context:} {}

\cs_generate_variant:Nn \msg_warning:nnn {nnV}

\cs_new:Npn \txt_load_file:n #1
{
  \seq_if_in:NnF \l__txt_lfiles_seq {#1}
  {
    \bool_if:NTF \l__txt_text_bool
    {
      \tl_set:Nn \l_tmpa_tl {internet#1.text.code.tex}
    }
    {
      \tl_set:Nn \l_tmpa_tl {internet#1.doc.code.tex}
    }
    \file_if_exist:nTF {\l_tmpa_tl}
    {
      \file_input:n {\l_tmpa_tl}
    }
    {
      \msg_warning:nnV {text} {no~ file} \l_tmpa_tl
    }
    \seq_put_right:Nn \l__txt_lfiles_seq {#1}
  }
}

\seq_concat:NNN \l__txt_files_seq \l__txt_files_seq \l__txt_mfiles_seq

\seq_map_function:NN \l__txt_files_seq \txt_load_file:n

% Local Variables:
% mode: latex3
% End:
