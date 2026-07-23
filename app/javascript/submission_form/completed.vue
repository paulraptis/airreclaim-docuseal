<template>
  <div
    id="form_completed"
    class="mx-auto max-w-md flex flex-col completed-form"
    dir="auto"
    role="status"
    tabindex="-1"
  >
    <div class="font-medium text-2xl flex items-center space-x-1.5 mx-auto text-center">
      <IconCircleCheck
        class="inline text-green-600"
        aria-hidden="true"
        :width="30"
        :height="30"
      />
      <span class="completed-form-message-title">
        {{ completedMessage.title || (hasSignatureFields ? (hasMultipleDocuments ? t('documents_have_been_signed') : t('document_has_been_signed')) : t('form_has_been_completed')) }}
      </span>
    </div>
    <div
      v-if="completedMessage.body"
      class="mt-2 completed-form-message-body"
    >
      <MarkdownContent
        :string="completedMessage.body"
      />
    </div>
    <div class="space-y-3 mt-5">
      <a
        v-if="completedButton.url"
        :href="sanitizeUrl(completedButton.url)"
        rel="noopener noreferrer nofollow"
        class="white-button flex items-center w-full completed-form-completed-button"
      >
        <span>
          {{ completedButton.title || 'Back to Website' }}
        </span>
      </a>
      <button
        v-if="canSendEmail && !isDemo && withSendCopyButton"
        class="white-button !h-auto flex items-center space-x-1 w-full completed-form-send-copy-button"
        :disabled="isSendingCopy"
        @click.prevent="sendCopyToEmail"
      >
        <IconInnerShadowTop
          v-if="isSendingCopy"
          class="animate-spin"
          aria-hidden="true"
        />
        <IconMail
          v-else
          aria-hidden="true"
        />
        <span>
          {{ t('send_copy_via_email') }}
        </span>
      </button>
      <button
        v-if="!isWebView && withDownloadButton"
        class="base-button flex items-center space-x-1 w-full completed-form-download-button"
        :disabled="isDownloading"
        :aria-describedby="downloadError ? 'completed_download_error' : undefined"
        @click.prevent="download"
      >
        <IconInnerShadowTop
          v-if="isDownloading"
          class="animate-spin"
          aria-hidden="true"
        />
        <IconDownload
          v-else
          aria-hidden="true"
        />
        <span>
          {{ downloadError ? t('try_download_again') : t('download') }}
        </span>
      </button>
      <div
        v-if="downloadError"
        id="completed_download_error"
        class="completed-form-download-error"
        role="alert"
        aria-live="assertive"
      >
        {{ t('failed_to_download_files') }}
      </div>
      <a
        v-if="isDemo"
        target="_blank"
        href="https://github.com/docusealco/docuseal"
        class="white-button flex items-center space-x-1 w-full"
      >
        <IconBrandGithub />
        <span>
          Star on Github
        </span>
      </a>
      <a
        v-if="isDemo"
        href="https://docuseal.com/sign_up"
        class="white-button flex items-center space-x-1 w-full"
      >
        <IconLogin />
        <span>
          {{ t('create_a_free_account') }}
        </span>
      </a>
    </div>
    <div
      v-if="attribution"
      class="text-center mt-4"
    >
      {{ t('document_signing_powered_by') }}
      <a
        href="https://www.docuseal.com/start"
        target="_blank"
        rel="noopener noreferrer"
        class="underline"
      >DocuSeal</a>
      <span aria-hidden="true"> | </span>
      <a
        href="/source/airreclaim-docuseal-3.1.2-ar.8.tar.gz"
        rel="nofollow"
        class="underline"
      >{{ t('source_code') }}</a>
    </div>
  </div>
</template>

<script>
import { IconCircleCheck, IconBrandGithub, IconMail, IconDownload, IconInnerShadowTop, IconLogin } from '@tabler/icons-vue'
import MarkdownContent from './markdown_content'
import { sanitizeUrl } from '@braintree/sanitize-url'

export default {
  name: 'FormCompleted',
  components: {
    MarkdownContent,
    IconCircleCheck,
    IconInnerShadowTop,
    IconBrandGithub,
    IconMail,
    IconLogin,
    IconDownload
  },
  inject: ['baseUrl', 't'],
  props: {
    submitterSlug: {
      type: String,
      required: true
    },
    isDemo: {
      type: Boolean,
      required: false,
      default: false
    },
    attribution: {
      type: Boolean,
      required: false,
      default: true
    },
    hasSignatureFields: {
      type: Boolean,
      required: false,
      default: false
    },
    hasMultipleDocuments: {
      type: Boolean,
      required: false,
      default: false
    },
    withDownloadButton: {
      type: Boolean,
      required: false,
      default: true
    },
    withSendCopyButton: {
      type: Boolean,
      required: false,
      default: true
    },
    withConfetti: {
      type: Boolean,
      required: false,
      default: false
    },
    canSendEmail: {
      type: Boolean,
      required: false,
      default: false
    },
    fetchOptions: {
      type: Object,
      required: false,
      default: () => ({})
    },
    completedDownloadUrl: {
      type: String,
      required: true
    },
    completedButton: {
      type: Object,
      required: false,
      default: () => ({})
    },
    completedMessage: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  data () {
    return {
      isSendingCopy: false,
      isDownloading: false,
      downloadError: false
    }
  },
  computed: {
    isWebView () {
      return /webview|wv|ip((?!.*Safari)|(?=.*like Safari))/i.test(window.navigator.userAgent)
    }
  },
  async mounted () {
    if (this.withConfetti) {
      const { default: confetti } = await import('canvas-confetti')

      confetti({
        particleCount: 50,
        startVelocity: 30,
        spread: 140
      })
    }

    document.querySelectorAll('#decline_button, #decline_button_mobile, #delegate_button, #delegate_button_mobile').forEach((button) => {
      button.setAttribute('disabled', 'true')
    })
  },
  methods: {
    sanitizeUrl,
    sendCopyToEmail () {
      this.isSendingCopy = true

      fetch(this.baseUrl + `/send_submission_email.json?submitter_slug=${this.submitterSlug}`, {
        method: 'POST'
      }).then(() => {
        alert(this.t('email_has_been_sent'))
      }).finally(() => {
        this.isSendingCopy = false
      })
    },
    async download () {
      this.isDownloading = true
      this.downloadError = false

      try {
        const response = await fetch(this.completedDownloadUrl, {
          method: 'GET',
          ...this.fetchOptions
        })

        if (!response.ok) {
          throw new Error('Completed document URL request failed')
        }

        const urls = await response.json()

        if (!Array.isArray(urls) || urls.length === 0 || urls.some((url) => typeof url !== 'string' || !url)) {
          throw new Error('Completed document URL response is invalid')
        }

        const isMobileSafariIos = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit/i.test(navigator.userAgent)
        const isSafariIos = isMobileSafariIos || /iPhone|iPad|iPod/i.test(navigator.userAgent)

        if (isSafariIos && urls.length > 1) {
          await this.downloadSafariIos(urls)
        } else {
          await this.downloadUrls(urls)
        }
      } catch (_error) {
        this.downloadError = true
      } finally {
        this.isDownloading = false
      }
    },
    async fetchDocumentBlob (url) {
      const response = await fetch(url)

      if (!response.ok) {
        throw new Error('Completed document request failed')
      }

      const blob = await response.blob()

      if (!blob.size) {
        throw new Error('Completed document is empty')
      }

      return blob
    },
    filenameFromUrl (url) {
      try {
        const pathname = new URL(url, window.location.origin).pathname

        return decodeURIComponent(pathname.split('/').filter(Boolean).pop()) || 'signed-document.pdf'
      } catch (_error) {
        return 'signed-document.pdf'
      }
    },
    async downloadUrls (urls) {
      const fileRequests = urls.map((url) => {
        return async () => {
          const blobUrl = URL.createObjectURL(await this.fetchDocumentBlob(url))
          const link = document.createElement('a')

          link.href = blobUrl
          link.setAttribute('download', this.filenameFromUrl(url))
          link.style.display = 'none'
          document.body.appendChild(link)
          link.click()
          link.remove()

          window.setTimeout(() => URL.revokeObjectURL(blobUrl), 1000)
        }
      })

      await fileRequests.reduce(
        (prevPromise, request) => prevPromise.then(() => request()),
        Promise.resolve()
      )
    },
    async downloadSafariIos (urls) {
      const fileRequests = urls.map((url) => {
        return this.fetchDocumentBlob(url).then((blob) => {
          const blobUrl = URL.createObjectURL(blob.slice(0, blob.size, 'application/octet-stream'))
          const link = document.createElement('a')

          link.href = blobUrl
          link.setAttribute('download', this.filenameFromUrl(url))
          link.style.display = 'none'
          document.body.appendChild(link)

          return link
        })
      })

      const links = await Promise.all(fileRequests)

      await Promise.all(links.map((link, index) => {
        return new Promise((resolve) => {
          window.setTimeout(() => {
            link.click()
            link.remove()
            window.setTimeout(() => URL.revokeObjectURL(link.href), 1000)
            resolve()
          }, index * 50)
        })
      }))
    }
  }
}
</script>
