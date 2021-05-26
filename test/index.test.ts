import { expect } from 'chai';
import { describe } from 'mocha';

import src from '../src';

describe('main', function () {
  it('should have been changed', () => {
    expect(src).to.not.throw();
  });
});
