import { target, targetable } from '@github/catalyst/lib/targetable'

export default targetable(class extends HTMLElement {
  static [target.static] = ['defaultButton', 'loadingButton']

  connectedCallback () {
    this.errorContainer = this.nextElementSibling?.matches?.('[data-download-error]')
      ? this.nextElementSibling
      : null
    this.retryButton = this.errorContainer?.querySelector?.('[data-download-retry]')
    this.isDownloading = false

    this.addEventListener('click', () => this.downloadFiles())
    this.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        this.downloadFiles()
      }
    })
    this.retryButton?.addEventListener('click', () => this.downloadFiles())
  }

  setLoading (loading) {
    this.defaultButton?.classList?.toggle('hidden', loading)
    this.loadingButton?.classList?.toggle('hidden', !loading)
    this.toggleAttribute('aria-disabled', loading)
    this.setAttribute('aria-busy', String(loading))
  }

  setError (visible) {
    this.errorContainer?.classList?.toggle('hidden', !visible)
    if (visible) this.errorContainer?.focus?.()
  }

  async downloadFiles () {
    if (!this.dataset.src || this.isDownloading) return

    this.isDownloading = true
    this.setError(false)
    this.setLoading(true)

    try {
      const response = await fetch(this.dataset.src)
      if (!response.ok) throw new Error('Completed document endpoint failed')

      const urls = await response.json()
      if (!Array.isArray(urls) || urls.length === 0 || !urls.every((url) => typeof url === 'string' && url.length > 0)) {
        throw new Error('Completed document endpoint returned invalid URLs')
      }

      const downloads = await Promise.all(urls.map(async (url) => {
        const fileResponse = await fetch(url)
        const contentType = fileResponse.headers.get('content-type') || ''
        if (!fileResponse.ok || !contentType.includes('application/pdf')) {
          throw new Error('Completed PDF request failed')
        }

        const blob = await fileResponse.blob()
        if (!blob.size) throw new Error('Completed PDF was empty')

        return { blob, url }
      }))

      const isMobileSafariIos = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit/i.test(navigator.userAgent)
      const isSafariIos = isMobileSafariIos || /iPhone|iPad|iPod/i.test(navigator.userAgent)

      downloads.forEach(({ blob, url }, index) => {
        const downloadBlob = isSafariIos && downloads.length > 1
          ? blob.slice(0, blob.size, 'application/octet-stream')
          : blob
        const blobUrl = URL.createObjectURL(downloadBlob)
        const link = document.createElement('a')

        link.href = blobUrl
        link.setAttribute('download', decodeURI(url.split('/').pop()))

        setTimeout(() => {
          link.click()
          URL.revokeObjectURL(blobUrl)
        }, isSafariIos ? index * 50 : 0)
      })
    } catch (_error) {
      this.setError(true)
    } finally {
      this.isDownloading = false
      this.setLoading(false)
    }
  }
})
