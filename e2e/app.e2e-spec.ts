import * as puppeteer from 'puppeteer';
import { by, element } from 'protractor';

describe('shouldroforion/stgcore-vigilantcouscous App', () => {
  it('should display welcome message', () => {

    puppeteer.launch()
      .then(function (browser) {
        browser.get('/');

        element(by.css('app-root h1')).getText()
          .then(function (pageText) {
            expect(pageText).toEqual('Your business is not');
          });
      });

  });
});
