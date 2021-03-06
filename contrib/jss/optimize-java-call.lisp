(in-package :jss)

(defvar *inhibit-jss-optimization* nil)

;; https://mailman.common-lisp.net/pipermail/armedbear-devel/2016-October/003726.html

(precompiler::define-function-position-lambda-transform jss::invoke-restargs (arglist form args)
  (declare (ignore arglist))
  (unless *inhibit-jss-optimization*
    (precompiler::precompile-function-call 
     `(jss::invoke-restargs-macro
          ,(second form)
          ,(car args) (list ,@(cdr args)) ,(fifth form)))))

(defmacro invoke-restargs-macro ( method object args &optional (raw? nil))
  (assert (eq (car args) 'list))
  (setq args (cdr args))
  (if (and (consp object) (eq (car object) 'quote))
      (let ((object (eval object)))
        (let* ((object-as-class
                 (or (ignore-errors (let ((*muffle-warnings* t)) (find-java-class object)))
                     `(find-java-class ',object))))
          (if raw?
              `(jstatic-raw ,method ,object-as-class ,@args)
              `(jstatic ,method ,object-as-class ,@args))))
      (let ((objectvar (make-symbol "INVOKE-RESTARGS-ARG1")))
        (if raw?
            `(let ((,objectvar ,object))
               (if (symbolp ,objectvar)
                   (jstatic-raw ,method (find-java-class ,objectvar) ,@args)
                   (jcall-raw ,method ,objectvar ,@args)))
            `(let ((,objectvar ,object))
               (if (symbolp ,objectvar)
                   (jstatic ,method (find-java-class ,objectvar) ,@args)
                   (jcall ,method ,objectvar ,@args)))))))



